trigger Example on Example__c (before insert, before update, before delete) {
    ExampleHandler.getInstance().process(Trigger.old, Trigger.new);
}