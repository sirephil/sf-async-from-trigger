/*
 * MIT License. See the associated LICENSE file.
 * 
 * Copyright sirephil (c) 2023.
 */

/**
 * The handler for DML against the Example__c object.
 */
public without sharing class ExampleHandler {
    /**
     * The transaction-wide concept of "now", designed to always be the same throughout the entire transaction
     * based on when this class is first loaded during the transaction.
     */
    private static final Datetime now = Datetime.now();

    /**
     * The transaction-wide tracking as to whether or not a "triggered event" has already been published for
     * a given event type.
     */
    private static final Set<String> published = new Set<String>();

    /**
     * Provides access to the singleton example handler.
     *
     * @return the singleton instance for this example handler. Will not be null.
     */
    public static ExampleHandler getInstance() {
        return (ExampleHandler) SingletonFactory.get(ExampleHandler.class);
    }

    /**
     * Allows the examples to be processed.
     *
     * @param oldExamples the example instances, in their previous state, to be processed. May be null.
     * @param newExamples the example instances, in their updated state, to be processed. May be null.
     */
    public void process(Example__c[] oldExamples, Example__c[] newExamples) {
        // This tracks whether there is at least one example that needs state processing in those
        // passed to this method.
        Boolean stateProcessingRequired = false;

        if (newExamples == null) {
            // This must be a deletion DML. This is currently ignored. This would need to be handled
            // by creating a record that represents the deletion, capturing the deleted record's ID
            // (and any other state data required for the later processing). These deletion placeholders
            // could then be used with a different Event Processor to ensure that deletions are
            // addressed appropriately.
            return;
        }

        for (Integer i = 0; i < newExamples.size(); i++) {
            Example__c original = oldExamples != null ? oldExamples[i] : null;
            Example__c updated = newExamples != null ? newExamples[i] : null;

            if (original == null || (updated != null &&
                    (original.Account__c != updated.Account__c ||
                    original.Datetime__c != updated.Datetime__c))) {
                // When one of these fields changes, or for each newly created example, it is necessary
                // to perform state processing.
                updated.StateProcessingLastRequired__c = now;

                stateProcessingRequired = true;
            }
        }

        String stateProcessor = ExampleProcessor.class.getName();

        if (!published.contains(stateProcessor) && stateProcessingRequired) {
            EventBus.publish(new TriggeredEvent__e(Type__c = stateProcessor));

            // This transaction-wide tracking update ensures that we only publish at most one
            // triggered event in a given transaction for this type of processing.
            published.add(stateProcessor);
        }
    }
}