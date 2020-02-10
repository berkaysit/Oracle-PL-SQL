/* T1: Simple test for database performance
*/
DECLARE
    v_last_timing  INTEGER := NULL;
    v_row_count    NUMBER;
BEGIN
    v_last_timing := dbms_utility.get_cpu_time;

--|> Count of rows to be generated and inserted:
-- Change the number to increase/decrease data volume.
    v_row_count := 100000;
    dbms_output.put_line('The Number of the Data to be Generated: ' || v_row_count);

--|> INSERT Operation:
-- dbms_random package is used for generating random number or string.
-- In the first column, we generate random number, then convert it to date. In the second column, we generate a string between 5 and 200 characters.
    INSERT INTO xx_random_datas
        SELECT
            level,
            to_date(trunc(dbms_random.value(2452641, 2452641 + 364)), 'J') random_date,
            dbms_random.string('A', trunc(dbms_random.value(5, 200))) random_string
        FROM dual
        CONNECT BY
            level <= v_row_count;

--|> ROLLBACK is executed to prevent the table space from being filled. (COMMIT can be used if needed.)
    ROLLBACK;

--|> Duration calculation in "Centisecond" (1 Centisecond = 0.01 seconds.)
    dbms_output.put_line('Completion time (centisecond): '
                         || to_char(dbms_utility.get_cpu_time - v_last_timing));
END;