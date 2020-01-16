# PL/SQL
I'll put together useful Oracle PL/SQL codes here.

# XXBS_RECORD_DIFF()
This function compares all the columns of a record with another record by using a unique identifier. The function can be used in a SELECT statement and outputs the columns with the old and new (changed) values. It dynamically generates and executes the SQL statement making the comparison.
