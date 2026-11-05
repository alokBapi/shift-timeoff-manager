trigger ShiftTrigger on Shift__c (before insert, before update) {
    ShiftTriggerHandler.checkOverlaps(Trigger.new);
}