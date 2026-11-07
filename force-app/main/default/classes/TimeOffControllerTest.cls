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
}