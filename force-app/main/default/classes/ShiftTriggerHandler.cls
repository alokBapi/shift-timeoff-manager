public with sharing class ShiftTriggerHandler {

    public static void checkOverlaps(List<Shift__c> newShifts) {
        List<Shift__c> toCheck = new List<Shift__c>();
        Set<Id> employeeIds = new Set<Id>();
        Set<Id> currentIds = new Set<Id>();
        Datetime minStart;
        Datetime maxEnd;

        for (Shift__c s : newShifts) {
            if (s.Id != null) currentIds.add(s.Id);
            if (s.Status__c == 'Cancelled' || s.Employee__c == null
                || s.Start_Time__c == null || s.End_Time__c == null) {
                continue;
            }
            toCheck.add(s);
            employeeIds.add(s.Employee__c);
            if (minStart == null || s.Start_Time__c < minStart) minStart = s.Start_Time__c;
            if (maxEnd == null || s.End_Time__c > maxEnd) maxEnd = s.End_Time__c;
        }
        if (toCheck.isEmpty()) return;

        // One query for the whole batch (bulk-safe)
        Map<Id, List<Shift__c>> existingByEmployee = new Map<Id, List<Shift__c>>();
        for (Shift__c e : [
            SELECT Id, Employee__c, Start_Time__c, End_Time__c
            FROM Shift__c
            WHERE Employee__c IN :employeeIds
              AND Status__c != 'Cancelled'
              AND Start_Time__c < :maxEnd
              AND End_Time__c > :minStart
              AND Id NOT IN :currentIds
        ]) {
            if (!existingByEmployee.containsKey(e.Employee__c)) {
                existingByEmployee.put(e.Employee__c, new List<Shift__c>());
            }
            existingByEmployee.get(e.Employee__c).add(e);
        }

        List<Shift__c> processed = new List<Shift__c>();
        for (Shift__c s : toCheck) {
            Boolean hasOverlap = false;

            List<Shift__c> existing = existingByEmployee.get(s.Employee__c);
            if (existing != null) {
                for (Shift__c other : existing) {
                    if (overlaps(s, other)) { hasOverlap = true; break; }
                }
            }
            if (!hasOverlap) {
                for (Shift__c other : processed) {
                    if (other.Employee__c == s.Employee__c && overlaps(s, other)) {
                        hasOverlap = true; break;
                    }
                }
            }
            if (hasOverlap) {
                s.addError('This employee already has a shift that overlaps this time.');
            }
            processed.add(s);
        }
    }

    private static Boolean overlaps(Shift__c a, Shift__c b) {
        return a.Start_Time__c < b.End_Time__c && a.End_Time__c > b.Start_Time__c;
    }
}