@isTest
private class ShiftTriggerHandlerTest {

    @TestSetup
static void setup() {
    insert new Employee__c(
        Name = 'Test Employee',
        Email__c = 'test@example.com',
        Department__c = 'Sales'
    );
}

    private static Shift__c makeShift(Id empId, Datetime startTime, Integer hours, String status) {
        return new Shift__c(
            Employee__c = empId,
            Start_Time__c = startTime,
            End_Time__c = startTime.addHours(hours),
            Status__c = status
        );
    }

    @isTest
    static void nonOverlappingShifts_areAllowed() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Datetime base = Datetime.now().addDays(1);
        insert makeShift(emp.Id, base, 4, 'Scheduled');
        insert makeShift(emp.Id, base.addHours(5), 4, 'Scheduled');
        System.assertEquals(2, [SELECT COUNT() FROM Shift__c]);
    }

    @isTest
    static void overlappingShift_isBlocked() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Datetime base = Datetime.now().addDays(1);
        insert makeShift(emp.Id, base, 4, 'Scheduled');

        Test.startTest();
        Database.SaveResult result = Database.insert(makeShift(emp.Id, base.addHours(2), 4, 'Scheduled'), false);
        Test.stopTest();

        System.assertEquals(false, result.isSuccess());
        System.assert(result.getErrors()[0].getMessage().contains('overlaps'));
    }

    @isTest
    static void cancelledShift_doesNotBlock() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Datetime base = Datetime.now().addDays(1);
        insert makeShift(emp.Id, base, 4, 'Cancelled');
        insert makeShift(emp.Id, base.addHours(1), 4, 'Scheduled');
        System.assertEquals(2, [SELECT COUNT() FROM Shift__c]);
    }

    @isTest
    static void bulkInsert_200Shifts_works() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Datetime base = Datetime.now().addDays(1);
        List<Shift__c> shifts = new List<Shift__c>();
        for (Integer i = 0; i < 200; i++) {
            shifts.add(makeShift(emp.Id, base.addHours(i * 2), 1, 'Scheduled'));
        }
        insert shifts;
        System.assertEquals(200, [SELECT COUNT() FROM Shift__c]);
    }

    @isTest
    static void overlapInsideSameBatch_isBlocked() {
        Employee__c emp = [SELECT Id FROM Employee__c LIMIT 1];
        Datetime base = Datetime.now().addDays(1);
        List<Shift__c> shifts = new List<Shift__c>{
            makeShift(emp.Id, base, 4, 'Scheduled'),
            makeShift(emp.Id, base.addHours(2), 4, 'Scheduled')
        };
        List<Database.SaveResult> results = Database.insert(shifts, false);
        System.assertEquals(true, results[0].isSuccess());
        System.assertEquals(false, results[1].isSuccess());
    }
}