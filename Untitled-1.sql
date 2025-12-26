select cast( completedDate as date) completedDate,
sum(Completed_Phone_Calls) Completed_Phone_Calls,
sum(Completed_Incoming_Phone_Calls) Completed_Incoming_Phone_Calls,
sum(Sent_Messages)+sum([TextSent]) Sent_Messages,

sum(Appointment)+sum(Community_Experience) Appointment,
sum(Completed_Phone_Calls_Biz_Dev)+sum(Sent_Messages_Biz_Dev)+sum(Appointment_Biz_Dev) Calls_Emails_Biz_Dev,

sum(Phone_Call_Attempted) Phone_Call_Attempted
    
    

from Vw_Activities
where CompletedDate >= convert(date,GETDATE() - 14) and CompletedDate <= convert(date,GETDATE() )
and [ActivityOwnerName] in (replace(substring(ltrim(rtrim(@DimUserFullName)),25,100),']',''))
group by cast( completedDate as date)