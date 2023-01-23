/*
 * MIT License. See the associated LICENSE file.
 * 
 * Copyright sirephil (c) 2023.
 */

/**
 * Simulates doing some heavy duty processing when some triggered event is raised for the Example__c
 * object.
 */
public without sharing class ExampleProcessor implements EventProcessor {
    /**
     * The transaction-wide concept of "now", designed to always be the same throughout the entire transaction
     * based on when this class is first loaded during the transaction.
     */
    private static final Datetime now = Datetime.now();

    // apexdoc inherited
    public void process(TriggeredEvent__e event) {
        // This code has no error handling for simplicity.
        List<Example__c> updates = new List<Example__c>();

        // Note that this query (which would normally be done in a Selector) has a specific limit
        // to simulate ensuring that the processing load be maintained at a sensible level.
        List<Example__c> examples = [
                SELECT Id, Account__r.Name, Datetime__c, Description__c
                    FROM Example__c
                    WHERE StateProcessingRequired__c = TRUE
                    ORDER BY Datetime__c
                    LIMIT 100
        ];

        for (Example__c example : examples) {
            // Pretend to do some work. This is where the processing that could not be done directly in
            // the trigger gets done. This could be some complex data updates, necessary callouts etc.
            // Clearly in this example there's not a lot actually done, but this is enough to show the
            // principle.
            String accountName = example.Account__r?.Name;
            String description = (accountName == null ? '(none)' : accountName ) + '@' +
                    example.Datetime__c.formatLong() + ' - ' +
                    event.ReplayId;

            // Ensure that this example is updated (using a new instance to ensure only the relevant
            // fields are updated, not all queried fields). Importantly, this update includes flagging that
            // the processing has been performed.
            updates.add(new Example__c(Id = example.Id,
                    Description__c = description,
                    StateProcessingLastPerformed__c = now));
        }

        update updates;
    }

    // apexdoc inherited
    public Boolean needsMoreProcessing() {
        // Note that this query (which would normally be done in a Selector) is used to test
        // whether there are records to be processed.
        return [SELECT COUNT() FROM Example__c WHERE StateProcessingRequired__c = TRUE] != 0;
    }
}