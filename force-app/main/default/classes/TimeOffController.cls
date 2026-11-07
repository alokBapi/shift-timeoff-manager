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
        @AuraEnabled(cacheable=true)
    public static List<Time_Off_Request__c> getSubmittedRequests() {
        return [
            SELECT Id, Name, Employee__r.Name, Start_Date__c, End_Date__c, Type__c, Reason__c
            FROM Time_Off_Request__c
            WHERE Status__c = 'Submitted'
            ORDER BY Start_Date__c
            LIMIT 200
        ];
    }

    @AuraEnabled
    public static void updateStatus(Id requestId, String newStatus) {
        if (newStatus != 'Approved' && newStatus != 'Rejected') {
            throw buildError('Invalid status.');
        }
        List<Time_Off_Request__c> found = [
            SELECT Id, Status__c FROM Time_Off_Request__c WHERE Id = :requestId LIMIT 1
        ];
        if (found.isEmpty()) {
            throw buildError('Request not found.');
        }
        Time_Off_Request__c req = found[0];
        if (req.Status__c != 'Submitted') {
            throw buildError('Only submitted requests can be approved or rejected.');
        }
        req.Status__c = newStatus;
        try {
            update req;
        } catch (DmlException e) {
            throw buildError(e.getDmlMessage(0));
        }
    }

    private static AuraHandledException buildError(String message) {
        AuraHandledException ex = new AuraHandledException(message);
        ex.setMessage(message);
        return ex;
    }
}