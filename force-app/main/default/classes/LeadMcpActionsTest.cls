@isTest
private class LeadMcpActionsTest {

    @testSetup
    static void setup() {
        insert new List<Lead>{
            new Lead(FirstName='Jane', LastName='Doe', Company='Acme Inc', Email='jane.doe@example.com', LeadSource='Web'),
            new Lead(FirstName='John', LastName='Smith', Company='Acme Inc', Email='john.smith@example.com', LeadSource='Referral')
        };
    }

    // ===================== LeadMcpCreate =====================

    @isTest static void testCreateLead_MinimalRequiredFields_DefaultsLeadSource() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'Sam';
        req.lastName = 'Lee';
        req.email = 'sam.lee@example.com';
        req.additionalFieldsJson = '{"Company":"Acme Inc"}';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Expected lead creation to succeed');
        Lead created = [SELECT LeadSource FROM Lead WHERE Id = :results[0].leadId];
        Assert.areEqual('Web', created.LeadSource, 'LeadSource should default to Web when not provided');
    }

    @isTest static void testCreateLead_ExplicitLeadSource_NotOverridden() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'Amy';
        req.lastName = 'Wu';
        req.email = 'amy.wu@example.com';
        req.additionalFieldsJson = '{"Company":"Acme Inc","LeadSource":"Referral"}';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Lead created = [SELECT LeadSource FROM Lead WHERE Id = :results[0].leadId];
        Assert.areEqual('Referral', created.LeadSource, 'Explicit LeadSource should not be overridden');
    }

    @isTest static void testCreateLead_AdditionalWritableFields_Applied() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'Bulk';
        req.lastName = 'Fields';
        req.email = 'bulk.fields@example.com';
        req.additionalFieldsJson = '{"Company":"Acme Inc","Website":"acme.com","Phone":"555-0100"}';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Lead created = [SELECT Website, Phone FROM Lead WHERE Id = :results[0].leadId];
        Assert.areEqual('acme.com', created.Website, 'Website should be set from additionalFieldsJson');
        Assert.areEqual('555-0100', created.Phone, 'Phone should be set from additionalFieldsJson');
    }

    @isTest static void testCreateLead_UnrecognizedField_Rejected() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'Nora';
        req.lastName = 'Kim';
        req.email = 'nora.kim@example.com';
        req.additionalFieldsJson = '{"Company":"Acme Inc","NotARealField__x":"value"}';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Lead should still be created despite one bad field');
        Assert.isTrue(results[0].message.contains('Ignored'), 'Message should note the ignored field');
    }

    @isTest static void testCreateLead_InvalidJson_ReturnsFailureWithoutInserting() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'Bad';
        req.lastName = 'Json';
        req.email = 'bad.json@example.com';
        req.additionalFieldsJson = '{not valid json';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Invalid JSON should cause failure');
        Assert.isTrue(results[0].message.contains('not valid JSON'), 'Message should explain the JSON parse failure');
    }

    @isTest static void testCreateLead_MissingRequiredCompany_TriggersDmlException() {
        LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
        req.firstName = 'No';
        req.lastName = 'Company';
        req.email = 'no.company@example.com';

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(new List<LeadMcpCreate.CreateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Missing required Company field should fail the DML');
        Assert.isTrue(results[0].message.contains('Failed to create Lead'), 'Message should surface the DML failure');
    }

    @isTest static void testCreateLead_BulkRequests() {
        List<LeadMcpCreate.CreateRequest> reqs = new List<LeadMcpCreate.CreateRequest>();
        for (Integer i = 0; i < 5; i++) {
            LeadMcpCreate.CreateRequest req = new LeadMcpCreate.CreateRequest();
            req.firstName = 'Bulk' + i;
            req.lastName = 'Test' + i;
            req.email = 'bulk' + i + '@example.com';
            req.additionalFieldsJson = '{"Company":"Acme Inc"}';
            reqs.add(req);
        }

        Test.startTest();
        List<LeadMcpCreate.LeadResult> results = LeadMcpCreate.createLead(reqs);
        Test.stopTest();

        Assert.areEqual(5, results.size(), 'Should return one result per request');
        for (LeadMcpCreate.LeadResult res : results) {
            Assert.isTrue(res.isSuccess, 'Each bulk lead should be created successfully');
        }
    }

    // ===================== LeadMcpGet =====================

    @isTest static void testGetLeads_ByEmail_ReturnsMatchingRecord() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
        req.fieldName = 'Email';
        req.fieldValue = 'jane.doe@example.com';
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(1, results[0].recordCount, 'Filter should match exactly one lead');
        Assert.isTrue(results[0].recordsJson.contains('jane.doe@example.com'), 'Returned JSON should contain the matched email');
    }
    
    @isTest static void testGetLeads_LikeOperator_MatchesPartialValue() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
        req.fieldName = 'LastName';
        req.fieldValue = 'Doe';
        req.operatorType = 'LIKE';
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(1, results[0].recordCount, 'LIKE filter should match the lead with that last name');
    }
    
    @isTest static void testGetLeads_MaxRecordsRespected() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
        req.maxRecords = 1;
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(1, results[0].recordCount, 'Result count should respect the maxRecords cap');
    }
    
    @isTest static void testGetLeads_DefaultLimitApplied_NoFilter() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(2, results[0].recordCount, 'Both seeded leads should be returned when unfiltered');
    }
    
    @isTest static void testGetLeads_InvalidFieldName_ReturnsFailureMessage() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
        req.fieldName = 'NotARealField__x';
        req.fieldValue = 'value';
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(0, results[0].recordCount, 'Invalid field should yield zero records');
        Assert.isTrue(results[0].message.contains('Unknown or inaccessible field'), 'Message should explain the rejected field');
    }
    
    @isTest static void testGetLeads_InvalidOperator_ReturnsFailureMessage() {
        LeadMcpGet.GetRequest req = new LeadMcpGet.GetRequest();
        req.fieldName = 'Email';
        req.fieldValue = 'jane.doe@example.com';
        req.operatorType = 'DROP';
    
        Test.startTest();
        List<LeadMcpGet.GetResult> results = LeadMcpGet.getLeads(new List<LeadMcpGet.GetRequest>{ req });
        Test.stopTest();
    
        Assert.areEqual(0, results[0].recordCount, 'Unsupported operator should yield zero records');
        Assert.isTrue(results[0].message.contains('Unsupported operator'), 'Message should explain the rejected operator');
    }

    // ===================== LeadMcpUpdate =====================

    @isTest static void testUpdateLead_ValidFields_Success() {
        Lead l = [SELECT Id FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        LeadMcpUpdate.UpdateRequest req = new LeadMcpUpdate.UpdateRequest();
        req.leadId = l.Id;
        req.fieldsJson = '{"Website":"acme.com","Title":"CTO"}';

        Test.startTest();
        List<LeadMcpUpdate.LeadResult> results = LeadMcpUpdate.updateLead(new List<LeadMcpUpdate.UpdateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Update with valid fields should succeed');
        Lead updated = [SELECT Website, Title FROM Lead WHERE Id = :l.Id];
        Assert.areEqual('acme.com', updated.Website, 'Website should be updated');
        Assert.areEqual('CTO', updated.Title, 'Title should be updated');
    }

    @isTest static void testUpdateLead_UnrecognizedField_Rejected() {
        Lead l = [SELECT Id FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        LeadMcpUpdate.UpdateRequest req = new LeadMcpUpdate.UpdateRequest();
        req.leadId = l.Id;
        req.fieldsJson = '{"NotARealField__x":"value"}';

        Test.startTest();
        List<LeadMcpUpdate.LeadResult> results = LeadMcpUpdate.updateLead(new List<LeadMcpUpdate.UpdateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Update should still succeed despite one bad field');
        Assert.isTrue(results[0].message.contains('Ignored'), 'Message should note the ignored field');
    }

    @isTest static void testUpdateLead_NoFieldsJson_StillSucceeds() {
        Lead l = [SELECT Id FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        LeadMcpUpdate.UpdateRequest req = new LeadMcpUpdate.UpdateRequest();
        req.leadId = l.Id;

        Test.startTest();
        List<LeadMcpUpdate.LeadResult> results = LeadMcpUpdate.updateLead(new List<LeadMcpUpdate.UpdateRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Update with no fieldsJson should still succeed as a no-op');
    }

    @isTest static void testUpdateLead_InvalidId_Fails() {
        LeadMcpUpdate.UpdateRequest req = new LeadMcpUpdate.UpdateRequest();
        req.leadId = '00Q000000000000AAA';
        req.fieldsJson = '{"Website":"acme.com"}';

        Test.startTest();
        List<LeadMcpUpdate.LeadResult> results = LeadMcpUpdate.updateLead(new List<LeadMcpUpdate.UpdateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Update on a nonexistent Id should fail');
        Assert.isTrue(results[0].message.contains('Failed to update Lead'), 'Message should surface the failure');
    }

    @isTest static void testUpdateLead_InvalidJson_Fails() {
        Lead l = [SELECT Id FROM Lead WHERE Email = 'jane.doe@example.com' LIMIT 1];
        LeadMcpUpdate.UpdateRequest req = new LeadMcpUpdate.UpdateRequest();
        req.leadId = l.Id;
        req.fieldsJson = '{not valid';

        Test.startTest();
        List<LeadMcpUpdate.LeadResult> results = LeadMcpUpdate.updateLead(new List<LeadMcpUpdate.UpdateRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Malformed JSON should cause the update to fail');
    }

    // ===================== LeadMcpDelete =====================

    @isTest static void testDeleteLead_ValidId_Success() {
        Lead l = [SELECT Id FROM Lead WHERE Email = 'john.smith@example.com' LIMIT 1];
        LeadMcpDelete.DeleteRequest req = new LeadMcpDelete.DeleteRequest();
        req.leadId = l.Id;

        Test.startTest();
        List<LeadMcpDelete.LeadResult> results = LeadMcpDelete.deleteLead(new List<LeadMcpDelete.DeleteRequest>{ req });
        Test.stopTest();

        Assert.isTrue(results[0].isSuccess, 'Delete with valid Id should succeed');
        Assert.areEqual(0, [SELECT COUNT() FROM Lead WHERE Id = :l.Id], 'Lead should no longer exist after delete');
    }

    @isTest static void testDeleteLead_InvalidId_Fails() {
        LeadMcpDelete.DeleteRequest req = new LeadMcpDelete.DeleteRequest();
        req.leadId = '00Q000000000000AAA';

        Test.startTest();
        List<LeadMcpDelete.LeadResult> results = LeadMcpDelete.deleteLead(new List<LeadMcpDelete.DeleteRequest>{ req });
        Test.stopTest();

        Assert.isFalse(results[0].isSuccess, 'Delete on a nonexistent Id should fail');
        Assert.isTrue(results[0].message.contains('Failed to delete Lead'), 'Message should surface the failure');
    }

    @isTest static void testDeleteLead_BulkRequests() {
        List<Lead> extra = new List<Lead>{
            new Lead(FirstName='A', LastName='B', Company='Acme Inc'),
            new Lead(FirstName='C', LastName='D', Company='Acme Inc')
        };
        insert extra;

        List<LeadMcpDelete.DeleteRequest> reqs = new List<LeadMcpDelete.DeleteRequest>();
        for (Lead l : extra) {
            LeadMcpDelete.DeleteRequest req = new LeadMcpDelete.DeleteRequest();
            req.leadId = l.Id;
            reqs.add(req);
        }

        Test.startTest();
        List<LeadMcpDelete.LeadResult> results = LeadMcpDelete.deleteLead(reqs);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Should return one result per bulk delete request');
        for (LeadMcpDelete.LeadResult res : results) {
            Assert.isTrue(res.isSuccess, 'Each bulk delete should succeed');
        }
    }
}