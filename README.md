# sf-async-from-trigger

Demonstrates how to scalably initiate out-of-transaction processing from an apex trigger using Platform Events

## Why?

* Avoid restricting DML to synchronous-only contexts.
* Allow callouts or limit-consuming processing on record changes.
* Ensure records are processed in a single-threaded manner (avoid race conditions and reduce record locking issues).

## What?

An apex trigger processes record creation, update, delete, undelete operations (or a subset thereof) for a given object. These are great for reacting to these changes to validate the records, apply further updates to these records, to (directly or indirectly) related records or to perform other operations. They have specific limitations because they execute synchronously, as part of a DML operation. A major limitation is the inability to perform a callout from within a trigger; callouts are used to initiate communication with (typically) external systems and are a common integration mechanism with off-platform software or systems.

Salesforce generally recommends performing callouts in a future method called from a trigger, but futures cannot be called when the initiating transaction itself is already asynchronous. That means it becomes impossible to make these callouts initiate from the trigger in a robust way that works in all contexts where that trigger could be called.

The above issue, and a whole bunch of other use cases are addressed by changing the approach and using Platform Events. Other important use cases are where you need to perform some specific processing, perhaps that is too costly in terms of CPU or other limits to include in the trigger, when a record is updated to meet certain criteria and where this processing must only be applied at most once for any given record change.

## How

This repo contains code that addresses the callout and/or governor limit related use cases in an elegant and robust manner.

This demonstration does not include any unit tests, but shows how you can use timestamp fields and a platform event to safely and robustly process records in a separate transaction to the one that detected a need for the processing.

The key parts of this solution are:

| Component | Description |
| - | - |
| Example__c | The custom object for which processing is required in this demo. Contains data fields plus the processing control fields. |
| Example.trigger<br/>ExampleHandler | The DML trigger and trigger handler for `Example__c`. |
| EventProcessor | The interface that represents processors for *types* of event. |
| ExampleProcessor | The `EventProcessor` implementation for handling `Example__c` records that need it. This does the "callout and/or governor limit consuming processing", as required. Here it simply does some simple data manipulation. |
| TriggeredEvent__e | The platform event published when an `Example__c` needs processing. Could be used for other objects too. Holds the *type* name for the processor that should be instantiated and run. |
| TriggeredEvent.trigger<br/>TriggeredEventHandler | The trigger-based Platform Event subscriber and handler for `TriggeredEvent__e`. Ensures that events for unique *types* of processor are consumed, executing a single `EventProcessor` for the first type and re-publishing unconsumed *types*. If the current *type* needs further processing, an additional event is published for this *type* in order to ensure it gets chained (after any unconsumed types). |

Note:

* Changes to the `Account__c` or the `Datetime__c` field values in `Example__c` records initiate the processing which (for demo purposes) is simply the need to update the `Description__c` field. This field is suffixed by the ID of the Platform Event that represents the processing execution so you can see which records get processed together. This is most interesting when you limit the `ExampleProcessor` to only process a few records together.
* The `TriggeredEvent__e` platform event `Type__c` field selects the processor to be run by being the *type* name for the `EventProcessor` to be instantiated.
* Additional implementations of the `EventProcessor` could easily be created if other *types* of processing was needed against the `Example__c` object, or even other object(s), in different situations.
* The Platform Event processing is single threaded, meaning there is no worry that the `Example__c` processing might face race conditions (a problem with `Queueable` and `Batchable` implementations where two or more instances of the same code can run concurrently and interfere with each other).

In terms of the general processing flow:

* The `Example__c` object's trigger detects the scenario where the processing is required and marks the record(s) that need to be processed. It ensures that at most one Platform Event is published for the `ExampleProcessor` in a given transaction when record(s) get marked for processing. This published event will be processed in a subsequent transaction.
* The `TriggeredEvent__e` event's trigger determines the *type(s)* of processing that are required and ensures that the first of these *types* gets executed. If that *type* cannot be fully executed in the trigger an appropriate event gets published to allow the trigger to be called again, for that *type*, in a subsequent transaction.
* Field history tracking has been enabled against `Example__c`'s `Account__c`, `Datetime__c` and `Description__c` fields so you can see "who" is doing what changes.

# Setup and Running the Demo

After deployment, assign the `Example` permission set to your user then access the `Examples` tab to start playing. You might also like to bulk create `Example` records to allow use of bulk updates in the `Examples` "All" list view to see how the processing behaves. Note how the processing encapsulated in the `ExampleProcessor` is attributed to the Automated Process user, while your changes are attributed to your user.

# Who caused the changes?

The records updated by the processor are marked as Last Modified By the Automated Process user too. This can be a good thing - you can see they have been processed by automation. If this is a significant problem, it is actually possible to engineer a flow-based Platform Event subscriber to replace this apex version. In this case the changes actually get attributed to the contextual user that caused the Platform Event to be published.
