Appointments:=CALCULATE(COUNTROWS(Fact_Activity),Fact_Activity[ActivityType] = "appointment",Fact_Activity[Result]="COMP - Completed" || Fact_Activity[Result]="CEXP - Community Experience Given", Fact_Activity[ActivityTypeDetail] <> 864960000 )

Appointments Biz Dev:=CALCULATE(COUNTROWS(Fact_Activity),Fact_Activity[ActivityType] = "appointment BD",Fact_Activity[Result]="COMP - Completed")

Completed Emails Biz Dev:=CALCULATE(COUNTROWS(Fact_Activity),Fact_Activity[ActivityType] = "email BD",Fact_Activity[ActivityTypeDetail]=864960002)
 
Completed Phone Calls:=CALCULATE (
    COUNTROWS ( Fact_Activity ),

           FILTER(Fact_Activity, Fact_Activity[ActivityType] = "phonecall"||(Fact_Activity[ActivityType] = "appointment" &&Fact_Activity[ActivityTypeDetail] = 864960000))
    ,
    Fact_Activity[Result] = "COMP - Completed"
)
 
Completed Phone Calls - ALL DATES:=CALCULATE (
    COUNTROWS ( Fact_Activity ),

            Fact_Activity[ActivityType] = "phonecall"
    ,
    Fact_Activity[Result] = "COMP - Completed"
    ,all(Dim_Date)
)
 
Completed Phone Calls - Not Incoming Calls:=CALCULATE (
    COUNTROWS ( Fact_Activity ),

           FILTER(Fact_Activity, Fact_Activity[ActivityType] = "phonecall")
    ,
    Fact_Activity[Result] = "COMP - Completed"
    ,Fact_Activity[ActivitySubject] <> "INCC - Incoming Call - COMP"
    ,Fact_Activity[ActivitySubject] <> "Incoming Call - COMP"
)
 
Completed Phone Calls Biz Dev:=CALCULATE(COUNTROWS(Fact_Activity),Fact_Activity[ActivityType] = "phonecall BD",Fact_Activity[Result]="COMP - Completed")
 
Completed Phone Calls Biz Dev Weekly Avg:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] = "phonecall BD",
    Fact_Activity[Result]="COMP - Completed"
) / DISTINCTCOUNT(Dim_Date[WeekOfYear])

Phone Calls Attempted:=CALCULATE (
    COUNTROWS ( Fact_Activity ),

            Fact_Activity[ActivityType] = "phonecall"
            ,Fact_Activity[Result] <> "BDCI - Bad Contact Information"
             ,Fact_Activity[Result] <> "CANC - Cancelled"
              ,Fact_Activity[Result] <> "COMP - Completed"
    ,Fact_Activity[ActivityTypeDetail] <> 864960000
)
 
Phone Calls Attempted - w Completed:=CALCULATE (
    COUNTROWS ( Fact_Activity ),

            Fact_Activity[ActivityType] = "phonecall"
            ,Fact_Activity[Result] <> "BDCI - Bad Contact Information"
             ,Fact_Activity[Result] <> "CANC - Cancelled"

    ,Fact_Activity[ActivityTypeDetail] <> 864960000
)

Sent Messages:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] = "email" ,
    Fact_Activity[ActivityTypeDetail]=864960002
) + CALCULATE(
        COUNTROWS(Fact_Activity),
        Fact_Activity[ActivityType] =  "letter",
        Fact_Activity[ActivityTypeDetail]=864960000
)

Texts Received:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] = "ksl_sms",
    Fact_Activity[ActivityTypeDetail] = 1001
)
 
Texts Sent:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] = "ksl_sms",
    Fact_Activity[ActivityTypeDetail] = 1002
)