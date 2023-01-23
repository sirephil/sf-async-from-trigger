# sf-async-from-trigger

Demonstrates how to scalably initiate out-of-transaction processing from an apex trigger using Platform Events.

This demonstration does not include any unit tests, but shows how you can use timestamp fields and a platform event to safely and robustly process records in a separate transaction to the one that detected a need for the processing.

The key parts are:

* The Example__c custom object for which processing is required. Changes to the Account__c or the Datetime__c field values initiate the processing which (for demo purposes) is simply the need to update the Description__c field.
* The ExampleProcessor that encapsulates the processing to be applied.
* The TriggeredEvent__e platform event that is used to initiate the required processing. This includes a Type__c field that simply selects the processor to be run - additional implementations of the EventProcessor could easily be created if other types of processing was needed against the Example__c object, or even other object(s), in different situations.

The Example__c object's trigger detects the scenario where the processing is required and marks the record(s) that need to be processed. It ensures that at most Platform Event is published for the ExampleProcessor in a given transaction when record(s) get marked for processing. This event will be processed in a subsequent transaction.

The TriggeredEvent__e event's trigger determines the type(s) of processing that are required and ensures that the first of these types gets executed. If that type cannot be fully executed in the trigger an appropriate event gets published to allow the trigger to be called again, for that type, in a subsequent transaction.

Field history tracking has been enabled against Example__c's Account__c, Datetime__c and Description__c fields.

After deployment, assign the Example permission set to your user then access the Examples tab to start playing. You might also like to bulk create Examples to allow use of bulk updates in the Examples "All" list view to see how the processing behaves. Note how the processing is attributed to the Automated Process user.