Appointments:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] IN { 
        "Unscheduled Walk-In", 
        "Committed Face Appointment"
    },
    Fact_Activity[Result]="Completed" 
)

Appointments Biz Dev:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] IN { 
        "Unscheduled Walk-In", 
        "Committed Face Appointment"
    },
    Fact_Activity[isBD] = "Yes",
    Fact_Activity[Result]="Completed"
)

Completed Phone Calls:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call", 
        "Committed Phone Appointment" 
    },
    Fact_Activity[Result] = "Completed"
)
 
Completed Phone Calls - ALL DATES:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call", 
        "Committed Phone Appointment" 
    },
    all(Dim_Date)
)
 
Completed Phone Calls - Not Incoming Calls:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Committed Phone Appointment" 
    },
    Fact_Activity[Result] = "Completed"
)
 
Completed Phone Calls Biz Dev:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call", 
        "Committed Phone Appointment" 
    },
    Fact_Activity[isBD] = "Yes",
    Fact_Activity[Result]="Completed"
)
 
Completed Phone Calls Biz Dev Weekly Avg:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call", 
        "Committed Phone Appointment" 
    },
    Fact_Activity[isBD] = "Yes",
    Fact_Activity[Result]="Completed")/ DISTINCTCOUNT(Dim_Date[WeekOfYear]
)

Phone Calls Attempted:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call",
        "Committed Phone Appointment"
    },
    Fact_Activity[Result] <> "Cancelled",
    Fact_Activity[Result] <> "Completed"
)
 
Phone Calls Attempted - w Completed:=CALCULATE (
    COUNTROWS ( Fact_Activity ),
    Fact_Activity[ActivityType] IN { 
        "Outgoing Phone Call", 
        "Incoming Phone Call",
        "Committed Phone Appointment"
    },
    Fact_Activity[Result] <> "Cancelled"
)

Sent Messages:=CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] = "Outbound Email"
) + CALCULATE(
    COUNTROWS(Fact_Activity),
    Fact_Activity[ActivityType] = "Letter"
)

Texts Received:=
CALCULATE ( 
    COUNTROWS ( Fact_Activity ), 
    Fact_Activity[ActivityType] = "Incoming Text Message" 
)
+ 
CALCULATE ( 
    COUNTROWS ( Fact_Activity ), 
    Fact_Activity[ActivityType] = "Text Message Conversation", 
    Fact_Activity[Result] = "Text Received" 
)

Texts Sent:=
CALCULATE ( 
    COUNTROWS ( Fact_Activity ), 
    Fact_Activity[ActivityType] = "Outgoing Text Message" 
)
+ 
CALCULATE ( 
    COUNTROWS ( Fact_Activity ), 
    Fact_Activity[ActivityType] = "Text Message Conversation", 
    Fact_Activity[Result] = "Text Sent" 
)
