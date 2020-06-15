CREATE OR REPLACE FUNCTION XXBS_RECORD_DIFF (
-- first try 15.06.2020
-- second try from VM
   p_Schema      IN VARCHAR2,
   p_Table       IN VARCHAR2,
   p_Key         IN VARCHAR2,
   p_FirstKey    IN VARCHAR2,
   p_SecondKey   IN VARCHAR2,
   p_Mode           VARCHAR2 DEFAULT 'RESULT')
   RETURN CLOB
IS
   v_count          NUMBER := 0;
   v_base_sql       VARCHAR2 (13000);
   v_lag_cols       VARCHAR2 (13000);
   v_case_sql       VARCHAR2 (13000);
   v_new_old_cols   VARCHAR2 (13000);
   v_final_sql      CLOB;                                   --VARCHAR2(32767);
   v_sql_output     VARCHAR2 (32000);
   v_result         VARCHAR2 (32767);
BEGIN
/**
 #Author: Berkay Sit (https://github.com/berkaysit)
 
 This function compares all the columns of a record with another record by using a unique identifier. Outputs the columns with the old and new (changed) values. It dynamically generates and executes the SQL statement making the comparison.
 
 PARAMETERs:
 p_FirstKey: Record to be queried in case of change from the old one (new record)
 p_SecondKey: Record from which to retrieve the old value. (old record)
 p_Mode: 'SQL': Returns the generated SQL statement that makes the comparison
         'RESULT': The differences found in the comparison result are returned in a sentence in English.
 
 RESTRICTIONS:
  Oracle Table Column Names can be up to 32 characters. Since the function adds the _ symbol to the existing column names, the column names entering this function must be up to 29 characters.
  
  KNOWN BUGs:
  The error "... buffer too small ..." is received for tables with too many columns.
  git commit test line
  git second commit
*/

   FOR LAG
      IN (  SELECT COLUMN_NAME, 
                    CASE WHEN LENGTH(COLUMN_NAME) >= 30 
                         THEN SUBSTR(COLUMN_NAME,1,29) 
                         ELSE COLUMN_NAME
                    END COLUMN_NAME_SBSTR,
                   COUNT (1) OVER (PARTITION BY TABLE_NAME) COL_COUNT
              FROM ALL_TAB_COLUMNS
             WHERE OWNER = p_Schema AND TABLE_NAME = p_Table
          ORDER BY COLUMN_ID)
   LOOP
      v_count := v_count + 1;

      --|> If you want to select the old and new values of columns when using SQL mode
      v_new_old_cols :=
            v_new_old_cols
         || '--'
         || LAG.COLUMN_NAME
         || ', '
         || CHR (10)
         || '--'
         || LAG.COLUMN_NAME_SBSTR
         || '_,'
         || CHR (10);

      --|> Outer Select;
      v_case_sql :=
            v_case_sql
         || 'CASE WHEN '
         || LAG.COLUMN_NAME
         || ' != '
         || LAG.COLUMN_NAME_SBSTR
         || '_ THEN '''
         || LAG.COLUMN_NAME
         || ' kolonunun eski de�eri ''||'
         || LAG.COLUMN_NAME_SBSTR
         || '_||'' iken ''||'
         || LAG.COLUMN_NAME
         || '||'' olmu�tur'' ||chr(10) END ||';
      --'||lag.COLUMN_NAME||'_FARK_ACIKLAMA, ';



      --> LAG Select: Creates LAG columns.
      v_lag_cols :=
            v_lag_cols
         || LAG.COLUMN_NAME
         || ', '
         || CHR (10)
         || 'LAG ('
         || LAG.COLUMN_NAME
         || ', 1) OVER (PARTITION BY DATA_GROUP ORDER BY SIRA) AS '
         || LAG.COLUMN_NAME_SBSTR
         || '_,'
         || CHR (10);


      --|> Create columns of Base Select sentence
      v_base_sql := v_base_sql || LAG.COLUMN_NAME || ', ';


      --|> steps in the last iteration; (only to be done once)

      IF v_count = LAG.COL_COUNT
      THEN
         --> Create the entire Base Select Sentence:
         v_base_sql :=
               'SELECT '
            || v_base_sql
            || ' ''A'' DATA_GROUP, CASE WHEN '
            || 'TO_CHAR(' || p_Key 
            || ') = '
            || ''''||p_FirstKey||''''
            || ' THEN 1 ELSE 2 END SIRA FROM '
            || p_Table
            || ' WHERE TO_CHAR('
            || p_Key
            || ') IN ('
            || ''''||p_FirstKey||''''
            || ','
            || ''''||p_SecondKey||''''
            || ') )'
            || ')
WHERE SIRA = 2';

         --> Complete the SELECT, FROM parts of LAG Select:
         v_lag_cols := 'SELECT ' || v_lag_cols || 'SIRA FROM (';

         --> Complete "CASE Select" parts:
         v_case_sql :=
               'SELECT '
            || v_new_old_cols
            || v_case_sql
            || ' ''''  CASE_SQL FROM (';
      END IF;
   END LOOP;

   --|> Prepare the complete SQL sentence.
   v_final_sql := v_case_sql || v_lag_cols || v_base_sql;



   --|> Return SQL statement result or SQL sentence according to selected mode
   IF p_Mode = 'RESULT'
   THEN
      --|> Run prepared SQL sentence.
      EXECUTE IMMEDIATE v_final_sql INTO v_sql_output;

      v_result := v_sql_output;
   ELSIF p_Mode = 'SQL'
   THEN
      v_result := v_final_sql;
   END IF;

   RETURN v_result;
EXCEPTION
   WHEN NO_DATA_FOUND
   THEN
      RETURN 'No data found!';
   WHEN OTHERS
   THEN
      -->ORA-00972: identifier is too long
      IF SQLCODE = -972
      THEN
         RAISE_APPLICATION_ERROR (
            -20001,
            'Table column names must be under 30 characters!');
      --> ORA-06535: statement string in EXECUTE IMMEDIATE is NULL or 0 length
      ELSIF SQLCODE = -06535
      THEN
         RAISE_APPLICATION_ERROR (-20001, 'Table not found!');
      --> ORA-00904: <COLUMN_NAME> invalid identifier
      ELSIF SQLCODE = -00904
      THEN
         RAISE_APPLICATION_ERROR (-20001,
                                  'Given Primary Key is not found!');
      ELSE
         --> Others
         RETURN SQLERRM;
         RAISE;
      END IF;
END XXBS_RECORD_DIFF;
/