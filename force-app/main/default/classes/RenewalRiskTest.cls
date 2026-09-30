@IsTest
private class RenewalRiskTest {

    @IsTest
    static void labelFormulaMatchesScoreBand() {
        Account low = new Account(Name = 'Blast Radius Low', Renewal_Risk_Score__c = 10);
        Account mid = new Account(Name = 'Blast Radius Mid', Renewal_Risk_Score__c = 60);
        Account high = new Account(Name = 'Blast Radius High', Renewal_Risk_Score__c = 90);
        insert new List<Account>{ low, mid, high };

        Map<Id, Account> byId = new Map<Id, Account>([
            SELECT Renewal_Risk_Label__c FROM Account WHERE Id IN :new List<Account>{ low, mid, high }
        ]);
        System.assertEquals('Low', byId.get(low.Id).Renewal_Risk_Label__c, 'Low band');
        System.assertEquals('Medium', byId.get(mid.Id).Renewal_Risk_Label__c, 'Medium band');
        System.assertEquals('High', byId.get(high.Id).Renewal_Risk_Label__c, 'High band');
    }

    @IsTest
    static void scoreOutOfRangeIsRejected() {
        Account acct = new Account(Name = 'Blast Radius Invalid', Renewal_Risk_Score__c = 150);
        Database.SaveResult result = Database.insert(acct, false);
        System.assert(!result.isSuccess(), 'Score above 100 should be rejected');
    }

    @IsTest
    static void flowStampsDescriptionWhenScoreChanges() {
        // Test.startTest()/stopTest() forces any after-save flow interview
        // to finish before the assertions run. Without this boundary,
        // execution order for record-triggered automation in a test
        // transaction is not guaranteed, so the query below could race
        // the flow's own update to Description.
        Test.startTest();
        Account acct = new Account(Name = 'Blast Radius Flow', Renewal_Risk_Score__c = 85);
        insert acct;
        Test.stopTest();

        String description = [SELECT Description FROM Account WHERE Id = :acct.Id].Description;
        // Split assertion, with the actual value in every failure message, so
        // a future failure says WHAT went wrong (null vs. wrong content)
        // instead of only that the flow "should have" stamped something.
        System.assertNotEquals(null, description, 'Flow did not set Description at all - it is null');
        System.debug('ACTUAL Description = ' + description);
        System.assert(description.contains('High'), 'Description should contain "High", was: ' + description);
        System.assert(description.contains('85'), 'Description should contain "85", was: ' + description);
    }
}