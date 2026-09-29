@isTest
private class AgentLeadCreateTest {

    @isTest static void testCreateLead_SetsLeadSourceToAgent() {
        AgentLeadCreate.CreateRequest req = new AgentLeadCreate.CreateRequest();
        req.firstName = 'Priya';
        req.lastName = 'Nair';
        req.email = 'priya.nair@fabrikam.com';
        req.additionalFieldsJson = '{"Company":"Fabrikam"}';

        Test.startTest();
        List<AgentLeadCreate.LeadResult> results = AgentLeadCreate.createLead(new List<AgentLeadCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Expected lead creation to succeed but got: ' + results[0].message);
        Lead created = [SELECT LeadSource FROM Lead WHERE Id = :results[0].leadId];
        Assert.areEqual('Agent', created.LeadSource, 'LeadSource should default to Agent for this channel');
    }

    @isTest static void testCreateLead_IgnoresAttemptToOverrideLeadSource() {
        AgentLeadCreate.CreateRequest req = new AgentLeadCreate.CreateRequest();
        req.firstName = 'Sam';
        req.lastName = 'Lee';
        req.email = 'sam.lee@fabrikam.com';
        req.additionalFieldsJson = '{"Company":"Fabrikam","LeadSource":"Referral"}';
    
        Test.startTest();
        List<AgentLeadCreate.LeadResult> results = AgentLeadCreate.createLead(new List<AgentLeadCreate.CreateRequest>{ req });
        Test.stopTest();
    
        Assert.isTrue(results[0].isSuccess, 'Expected lead creation to succeed but got: ' + results[0].message);
    
        Lead created = [SELECT LeadSource FROM Lead WHERE Id = :results[0].leadId];
        Assert.areEqual('Agent', created.LeadSource, 'LeadSource should stay Agent even if the caller tries to override it');
    }

    @isTest static void testCreateLead_PlaceholderEmail_Rejected() {
        AgentLeadCreate.CreateRequest req = new AgentLeadCreate.CreateRequest();
        req.firstName = 'Jane';
        req.lastName = 'Doe';
        req.email = 'jane@company.com';

        Test.startTest();
        List<AgentLeadCreate.LeadResult> results = AgentLeadCreate.createLead(new List<AgentLeadCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Placeholder-looking values should be rejected');
    }
}