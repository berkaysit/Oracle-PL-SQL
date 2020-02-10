DECLARE
    v_last_timing           INTEGER := NULL;
    v_row_count             NUMBER := 0;
    --|> new collection type: nested table type
    TYPE ntt_xx_random_datas IS
        TABLE OF xx_random_datas%rowtype;
    --|> nested table based on ntt_xx_random_datas
    ntt_generated_data_set  ntt_xx_random_datas := ntt_xx_random_datas();
BEGIN
--|> Count of rows to be generated and inserted:
-- Change the number to increase/decrease data volume.
    v_row_count := 100000;
    dbms_output.put_line('The Number of the Data to be Generated: ' || v_row_count);

--|> Random Data Generation:
-- dbms_random package is used for generating random number or string.
-- In the first column, we generate random number, then convert it to date.
-- In the second column, we generate a string between 5 and 200 characters.
    v_last_timing := dbms_utility.get_cpu_time;
    SELECT
        level,
        to_date(trunc(dbms_random.value(2452641, 2452641 + 364)), 'J')               AS "random_date",
        dbms_random.string('A', trunc(dbms_random.value(5, 200)))                    AS "random_string"
    BULK COLLECT
    INTO ntt_generated_data_set
    FROM
        dual
    CONNECT BY
        level <= v_row_count;

--|> Duration calculation in "Centisecond" (1 Centisecond = 0.01 seconds.)
    dbms_output.put_line('Random Data Generation: '
                         || to_char(dbms_utility.get_cpu_time - v_last_timing) || ' centiseconds');
    v_last_timing := NULL;


--|> INSERT Operation (FORALL): (BEST PRACTICE)
-- FORALL makes the context switch only once.
    v_last_timing := dbms_utility.get_cpu_time;
    FORALL i IN 1..ntt_generated_data_set.COUNT
        INSERT INTO xx_random_datas (
            id,
            date_col,
            text_col
        ) VALUES (
            ntt_generated_data_set(i).id,
            ntt_generated_data_set(i).date_col,
            ntt_generated_data_set(i).text_col
        );
        
--|> Duration calculation in "Centisecond" (1 Centisecond = 0.01 seconds.)
    dbms_output.put_line('1.INSERT Operation Duration (FORALL): '
                         || to_char(dbms_utility.get_cpu_time - v_last_timing) || ' centiseconds');
    v_last_timing := NULL;

--|> INSERT Operation: (For Loop): (NOT A GOOD WAY)
-- In this way, many context switches occur between PL/SQL Engine and SQL Engine which cause performans problem.
    v_last_timing := dbms_utility.get_cpu_time;
    FOR i IN 1..ntt_generated_data_set.COUNT
    LOOP
        INSERT INTO xx_random_datas (
            id,
            date_col,
            text_col
        ) VALUES (
            ntt_generated_data_set(i).id,
            ntt_generated_data_set(i).date_col,
            ntt_generated_data_set(i).text_col
        );

    END LOOP;
--|> Duration calculation in "Centisecond" (1 Centisecond = 0.01 seconds.)

    dbms_output.put_line('2.INSERT Operation Duration (For Loop): (centisecond): '
                         || to_char(dbms_utility.get_cpu_time - v_last_timing) || ' centiseconds');
    v_last_timing := NULL;
    
--|> ROLLBACK is executed to prevent the table space from being filled. (COMMIT can be used if needed.)
    ROLLBACK;
END;