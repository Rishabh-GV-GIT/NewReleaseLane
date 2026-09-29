global class LeadMcpCreate {

    global class CreateRequest {
        @InvocableVariable(required=true) global String firstName;
        @InvocableVariable(required=true) global String lastName;
        @InvocableVariable(required=true) global String email;
        @InvocableVariable(description='JSON object of additional Lead field API names to values, e.g. {"Website":"acme.com","LeadSource":"Referral"}')
        global String additionalFieldsJson;
    }

    global class LeadResult {
        @InvocableVariable global String leadId;
        @InvocableVariable global String message;
        @InvocableVariable global Boolean isSuccess;
    }

    @InvocableMethod(label='Create Lead' description='Creates a new Lead in Salesforce. Requires firstName, lastName, and email -- these must be values the user has explicitly stated in the conversation. Never invent, guess, or substitute placeholder values for any of these fields. If the user has not provided all three, do not call this tool; ask the user directly and wait for their reply first. Any other Lead field can be passed via additionalFieldsJson. If LeadSource is not supplied, it defaults to "Web".')
    global static List<LeadResult> createLead(List<CreateRequest> reqs) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        List<LeadResult> results = new List<LeadResult>();

        for (CreateRequest r : reqs) {
            LeadResult res = new LeadResult();
            Lead l = new Lead(
                FirstName = r.firstName,
                LastName  = r.lastName,
                Email     = r.email
            );

            List<String> rejectedFields = new List<String>();
            Boolean leadSourceProvided = false;

            if (String.isNotBlank(r.additionalFieldsJson)) {
                Map<String, Object> extras;
                try {
                    extras = (Map<String, Object>) JSON.deserializeUntyped(r.additionalFieldsJson);
                } catch (Exception e) {
                    res.isSuccess = false;
                    res.message = 'additionalFieldsJson was not valid JSON: ' + e.getMessage();
                    results.add(res);
                    continue;
                }

                for (String key : extras.keySet()) {
                    Schema.SObjectField f = fieldMap.get(key.toLowerCase());
                    if (f != null && f.getDescribe().isCreateable()) {
                        l.put(f, extras.get(key));
                        if (key.equalsIgnoreCase('LeadSource')) {
                            leadSourceProvided = true;
                        }
                    } else {
                        rejectedFields.add(key);
                    }
                }
            }

            if (!leadSourceProvided) {
                l.LeadSource = 'Web';
            }

            try {
                insert l;
                res.isSuccess = true;
                res.leadId = l.Id;
                res.message = rejectedFields.isEmpty() ? 'Lead created successfully.' : 'Lead created. Ignored unrecognized or non-writable fields: ' + String.join(rejectedFields, ', ');
            } catch (DmlException e) {
                res.isSuccess = false;
                res.message = 'Failed to create Lead: ' + e.getDmlMessage(0);
            }
            results.add(res);
        }
        return results;
    }
}