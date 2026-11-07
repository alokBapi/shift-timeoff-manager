@isTest
private class TimeOffControllerTest {

    @TestSetup
    static void setup() {
        insert new Employee__c(Name = 'Test Employee', Email__c = 'test@example.com',
                               Department__c = 'Sales');
    }

    @isTest
    static void getEmployees_returnsRecords() {
        System.assertEquals(1, TimeOffController.getEmployees().size());
    }

    @isTest
    static void submitRequest_createsSubmittedRecord() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Id reqId = TimeOffController.submitRequest(emp.Id, Date.today().addDays(5),
            Date.today().addDays(7), 'Annual', 'Family trip');
        Time_Off_Request__c saved = [SELECT Status__c, Type__c FROM Time_Off_Request__c WHERE Id = :reqId];
        System.assertEquals('Submitted', saved.Status__c);
        System.assertEquals('Annual', saved.Type__c);
    }

    @isTest
    static void submitRequest_endBeforeStart_throws() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        try {
            TimeOffController.submitRequest(emp.Id, Date.today().addDays(7),
                Date.today().addDays(5), 'Annual', null);
            System.assert(false, 'Expected an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('End date'));
        }
    }
        @isTest
    static void getSubmittedRequests_returnsOnlySubmitted() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        TimeOffController.submitRequest(emp.Id, Date.today().addDays(5),
            Date.today().addDays(6), 'Annual', null);
        insert new Time_Off_Request__c(Employee__c = emp.Id,
            Start_Date__c = Date.today().addDays(10), End_Date__c = Date.today().addDays(11),
            Type__c = 'Sick', Status__c = 'Draft');
        System.assertEquals(1, TimeOffController.getSubmittedRequests().size());
    }

    @isTest
    static void updateStatus_approvesSubmittedRequest() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Id reqId = TimeOffController.submitRequest(emp.Id, Date.today().addDays(5),
            Date.today().addDays(6), 'Annual', null);
        TimeOffController.updateStatus(reqId, 'Approved');
        System.assertEquals('Approved',
            [SELECT Status__c FROM Time_Off_Request__c WHERE Id = :reqId].Status__c);
    }

    @isTest
    static void updateStatus_invalidStatus_throws() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Id reqId = TimeOffController.submitRequest(emp.Id, Date.today().addDays(5),
            Date.today().addDays(6), 'Annual', null);
        try {
            TimeOffController.updateStatus(reqId, 'Banana');
            System.assert(false, 'Expected an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Invalid'));
        }
    }

    @isTest
    static void updateStatus_alreadyDecided_throws() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Id reqId = TimeOffController.submitRequest(emp.Id, Date.today().addDays(5),
            Date.today().addDays(6), 'Annual', null);
        TimeOffController.updateStatus(reqId, 'Rejected');
        try {
            TimeOffController.updateStatus(reqId, 'Approved');
            System.assert(false, 'Expected an exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Only submitted'));
        }
    }
}