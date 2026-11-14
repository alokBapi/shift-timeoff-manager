public with sharing class WeeklyShiftSummary implements Schedulable {

    public void execute(SchedulableContext sc) {
        sendSummary();
    }

    public static void sendSummary() {
        String body = buildSummary(System.now(), System.now().addDays(7));
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
        mail.setSubject('Weekly Shift Summary');
        mail.setPlainTextBody(body);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    @TestVisible
    private static String buildSummary(Datetime fromTime, Datetime toTime) {
        List<AggregateResult> rows = [
            SELECT Employee__r.Name empName, COUNT(Id) shiftCount
            FROM Shift__c
            WHERE Status__c = 'Scheduled'
              AND Start_Time__c >= :fromTime
              AND Start_Time__c < :toTime
            GROUP BY Employee__r.Name
            ORDER BY Employee__r.Name
        ];
        if (rows.isEmpty()) {
            return 'No shifts scheduled for the coming week.';
        }
        String body = 'Scheduled shifts for the next 7 days:\n';
        for (AggregateResult ar : rows) {
            body += '\n' + (String) ar.get('empName') + ': ' + (Integer) ar.get('shiftCount');
        }
        return body;
    }
}