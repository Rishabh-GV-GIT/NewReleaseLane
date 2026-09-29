global class AgentLeadCreate {

    global class CreateRequest {
        @InvocableVariable(required=true) global String firstName;
        @InvocableVariable(required=true) global String lastName;
        @InvocableVariable(required=true) global String email;
        @InvocableVariable(description='JSON object of additional Lead field API names to values, using only values the user explicitly stated')
        global String additionalFieldsJson;
    }

    global class LeadResult {
        @InvocableVariable global String leadId;
        @InvocableVariable global String message;
        @InvocableVariable global Boolean isSuccess;
    }

    private static final Set<String> PLACEHOLDER_NAMES = new Set<String>{
        'john doe', 'jane doe', 'test', 'test user', 'unknown',
        'n/a', 'tbd', 'firstname', 'lastname', 'user', 'customer'
    };

    private static final Set<String> GENERIC_DOMAIN_WORDS = new Set<String>{
        'company', 'business', 'corp', 'acme', 'test', 'sample', 'email',
        'mail', 'myco', 'yourcompany', 'domain', 'example', 'yourdomain',
        'website', 'org', 'demo', 'inc', 'firm'
    };

    @InvocableMethod(label='Create Lead' description='Creates a new Lead in Salesforce from within an Agentforce conversation. Requires firstName, lastName, and email -- these must be values the user explicitly stated. Never invent, guess, or substitute placeholder values. LeadSource is automatically set to "Agent".')
    global static List<LeadResult> createLead(List<CreateRequest> reqs) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        List<LeadResult> results = new List<LeadResult>();

        for (CreateRequest r : reqs) {
            LeadResult res = new LeadResult();

            String flagged = detectPlaceholder(r.firstName, r.lastName, r.email);
            if (flagged != null) {
                res.isSuccess = false;
                res.message = 'Rejected: ' + flagged + '. '
                    + 'Ask the user for their real first name, last name, and email, then call this action again with their actual answer.';
                results.add(res);
                continue;
            }

            Lead l = new Lead(
                FirstName  = r.firstName,
                LastName   = r.lastName,
                Email      = r.email,
                LeadSource = 'Agent'   // fixed for this channel; not user- or model-settable
            );

            List<String> rejectedFields = new List<String>();

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
                    if (key.equalsIgnoreCase('LeadSource')) {
                        continue; // LeadSource is fixed to 'Agent' for this channel; ignore any attempt to override it
                    }
                    Schema.SObjectField f = fieldMap.get(key.toLowerCase());
                    if (f != null && f.getDescribe().isCreateable()) {
                        l.put(f, extras.get(key));
                    } else {
                        rejectedFields.add(key);
                    }
                }
            }

            try {
                insert l;
                res.isSuccess = true;
                res.leadId = l.Id;
                res.message = rejectedFields.isEmpty()
                    ? 'Lead created successfully.'
                    : 'Lead created. Ignored unrecognized or non-writable fields: ' + String.join(rejectedFields, ', ');
            } catch (DmlException e) {
                res.isSuccess = false;
                res.message = 'Failed to create Lead: ' + e.getDmlMessage(0);
            }
            results.add(res);
        }
        return results;
    }

    private static String detectPlaceholder(String firstName, String lastName, String email) {
        if (firstName != null && PLACEHOLDER_NAMES.contains(firstName.trim().toLowerCase())) {
            return 'firstName ("' + firstName + '") looks like a placeholder, not a real name';
        }
        if (lastName != null && PLACEHOLDER_NAMES.contains(lastName.trim().toLowerCase())) {
            return 'lastName ("' + lastName + '") looks like a placeholder, not a real name';
        }

        if (String.isNotBlank(email) && email.contains('@')) {
            String domainFull = email.substringAfter('@').trim().toLowerCase();
            String domainBase = domainFull.contains('.') ? domainFull.substringBefore('.') : domainFull;

            if (GENERIC_DOMAIN_WORDS.contains(domainBase)) {
                return 'email ("' + email + '") uses a generic placeholder-style domain';
            }
        }
        return null;
    }
}