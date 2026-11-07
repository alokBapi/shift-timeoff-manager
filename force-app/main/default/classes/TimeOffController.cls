public with sharing class TimeOffController {

    @AuraEnabled(cacheable=true)
    public static List<Employee__c> getEmployees() {
        return [SELECT Id, Name FROM Employee__c ORDER BY Name LIMIT 200];
    }

    @AuraEnabled
    public static Id submitRequest(Id employeeId, Date startDate, Date endDate,
                                   String leaveType, String reason) {
        Time_Off_Request__c req = new Time_Off_Request__c(
            Employee__c = employeeId,
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Type__c = leaveType,
            Reason__c = reason,
            Status__c = 'Submitted'
        );
        try {
            insert req;
        } catch (DmlException e) {
            throw buildError(e.getDmlMessage(0));
        }
        return req.Id;
    }

    private static AuraHandledException buildError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}