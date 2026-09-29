global class LeadMcpUpdate {

    global class UpdateRequest {
        @InvocableVariable(required=true) global String leadId;
        @InvocableVariable(description='JSON object of Lead field API names to new values')
        global String fieldsJson;
    }

    global class LeadResult {
        @InvocableVariable global String leadId;
        @InvocableVariable global String message;
        @InvocableVariable global Boolean isSuccess;
    }

    @InvocableMethod(label='Update Lead' description='Updates an existing Lead by Id. Pass the fields to change as a JSON object.')
    global static List<LeadResult> updateLead(List<UpdateRequest> reqs) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        List<LeadResult> results = new List<LeadResult>();

        for (UpdateRequest r : reqs) {
            LeadResult res = new LeadResult();
            try {
                Lead l = new Lead(Id = r.leadId);
                List<String> rejectedFields = new List<String>();

                if (String.isNotBlank(r.fieldsJson)) {
                    Map<String, Object> fields = (Map<String, Object>) JSON.deserializeUntyped(r.fieldsJson);
                    for (String key : fields.keySet()) {
                        Schema.SObjectField f = fieldMap.get(key.toLowerCase());
                        if (f != null && f.getDescribe().isUpdateable()) {
                            l.put(f, fields.get(key));
                        } else {
                            rejectedFields.add(key);
                        }
                    }
                }

                update l;
                res.isSuccess = true;
                res.leadId = l.Id;
                res.message = rejectedFields.isEmpty() ? 'Lead updated successfully.' : 'Lead updated. Ignored unrecognized or non-writable fields: ' + String.join(rejectedFields, ', ');
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Failed to update Lead: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}