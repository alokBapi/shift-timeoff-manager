@isTest
private class WeeklyShiftSummaryTest {

    @TestSetup
    static void setup() {
        Employee__c emp = new Employee__c(Name = 'Test Employee',
            Email__c = 'test@example.com', Department__c = 'Sales');
        insert emp;
        Datetime base = Datetime.now().addDays(1);
        insert new List<Shift__c>{
            new Shift__c(Employee__c = emp.Id, Start_Time__c = base,
                End_Time__c = base.addHours(4), Status__c = 'Scheduled'),
            new Shift__c(Employee__c = emp.Id, Start_Time__c = base.addHours(24),
                End_Time__c = base.addHours(28), Status__c = 'Scheduled')
        };
    }

    @isTest
    static void buildSummary_countsScheduledShifts() {
        String body = WeeklyShiftSummary.buildSummary(Datetime.now(), Datetime.now().addDays(7));
        System.assert(body.contains('Test Employee: 2'));
    }

    @isTest
    static void buildSummary_noShifts() {
        String body = WeeklyShiftSummary.buildSummary(
            Datetime.now().addDays(30), Datetime.now().addDays(37));
        System.assert(body.contains('No shifts'));
    }

    @isTest
    static void sendSummary_sendsOneEmail() {
        Test.startTest();
        WeeklyShiftSummary.sendSummary();
        Integer emails = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, emails);
    }

    @isTest
    static void schedule_registersJob() {
        Test.startTest();
        String jobId = System.schedule('Test Weekly Summary', '0 0 8 ? * MON',
            new WeeklyShiftSummary());
        Test.stopTest();
        CronTrigger ct = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals('0 0 8 ? * MON', ct.CronExpression);
    }
}