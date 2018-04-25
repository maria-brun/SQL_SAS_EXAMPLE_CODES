********************************************************************************************************
Template for appending files from a database to create a rolling 12 month table and refreshing/updating 
as time goes  forward. Individual tables must have a year and month identifier in the name 
*******************************************************************************************************;

********************************************************************************************************
Set libnames for where the individual files are housed and where the appended data table will go 
*******************************************************************************************************;

LIBNAME ORIGIN ODBC NOPROMPT="File Location Here" SCHEMA=DBO BULKLOAD=YES;
LIBNAME DESTINATION ODBC NOPROMPT="File Location Here" SCHEMA=DBO BULKLOAD=YES;


********************************************************************************************************
Delete the existing table from the destination database
*******************************************************************************************************;

PROC DELETE DATA = DESTINATION.TABLE_NAME; RUN;


********************************************************************************************************
Macro to compile and append files, one year at a time
*******************************************************************************************************;

%Macro ROLLING_1YR(YEAR);
%let LIST=;

%do i=1 %to 12;
%if (&i<10)   %then %let i=0&i;
%let LIFTDS=;
      %if (&i<=&mn) and %sysfunc(exist(ORIGIN.DATA_&YEAR._&i))         %then %let LIFTDS=1;
%else %if (&i>&mn) and %sysfunc(exist(ORIGIN.DATA_%eval(&YEAR-1)_&i)) %then %let LIFTDS=1;
      %if (&i<=&mn) and (&LIFTDS=1) %then %let LIST=&LIST ORIGIN.DATA_&YEAR._&i;
%else %if (&i> &mn) and (&LIFTDS=1) %then %let LIST=&LIST ORIGIN.DATA_%eval(&YEAR-1)_&i;
%end;


%put &LIST;


data DATA_TIMESERIES_1YR_&YEAR; 
set &LIST;
run;


%Mend ROLLING_1YR;

%ROLLING_1YR(&yr.)
%ROLLING_1YR(%eval(&yr.-1))


********************************************************************************************************
Macro to append multiple years, if applicable
*******************************************************************************************************;

%Macro APPEND();

%let LIST=;

	%if %sysfunc(exist(DATA_TIMESERIES_1YR_&yr))%then %let LIST=&LIST DATA_TIMESERIES_1YR_&yr;
	%if %sysfunc(exist(DATA_TIMESERIES_1YR_%eval(&yr-1)))%then %let LIST=&LIST DATA_TIMESERIES_1YR_%eval(&yr-1);

%put &LIST;


data TABLE_NAME; 
set &LIST;
run;


%Mend APPEND;

%APPEND;

data DESTINATION.TABLE_NAME; set TABLE_NAME;
RUN;