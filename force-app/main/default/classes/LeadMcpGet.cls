global class LeadMcpGet {

    private static final Set<String> ALLOWED_OPERATORS = new Set<String>{ '=', '!=', 'LIKE' };

    global class GetRequest {
        @InvocableVariable(description='API name of the Lead field to filter on, e.g. Email, LastName, Id. Leave blank to return records unfiltered.')
        global String fieldName;
        @InvocableVariable(description='Value to match against fieldName.')
        global String fieldValue;
        @InvocableVariable(description='Comparison operator: =, !=, or LIKE. Defaults to = if not provided.')
        global String operatorType;
        @InvocableVariable global Integer maxRecords;
    }

    global class LeadRow {
        @InvocableVariable global String leadId;
        @InvocableVariable global String firstName;
        @InvocableVariable global String lastName;
        @InvocableVariable global String email;
        @InvocableVariable global String company;
        @InvocableVariable global String leadSource;
        @InvocableVariable global String status;
        @InvocableVariable global String website;
        @InvocableVariable global String phone;
    }

    global class GetResult {
        @InvocableVariable global String recordsJson;
        @InvocableVariable global List<LeadRow> leads;
        @InvocableVariable global Integer recordCount;
        @InvocableVariable global String message;
    }

    @InvocableMethod(label='Get Leads' description='Retrieves Lead records, optionally filtered by a single field/value pair. Returns matching records as JSON and as a structured list for UI display.')
    global static List<GetResult> getLeads(List<GetRequest> reqs) {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Lead.fields.getMap();
        List<GetResult> results = new List<GetResult>();

        for (GetRequest r : reqs) {
            GetResult res = new GetResult();
            Integer lim = (r.maxRecords != null && r.maxRecords > 0) ? r.maxRecords : 50;
            String query = 'SELECT Id, FirstName, LastName, Email, Company, LeadSource, Status, Website, Phone FROM Lead';

            if (String.isNotBlank(r.fieldName)) {
                Schema.SObjectField f = fieldMap.get(r.fieldName.toLowerCase());
                if (f == null || !f.getDescribe().isAccessible()) {
                    res.message = 'Unknown or inaccessible field: ' + r.fieldName;
                    res.recordCount = 0;
                    results.add(res);
                    continue;
                }

                String op = String.isBlank(r.operatorType) ? '=' : r.operatorType.toUpperCase();
                if (!ALLOWED_OPERATORS.contains(op)) {
                    res.message = 'Unsupported operator: ' + r.operatorType + '. Use =, !=, or LIKE.';
                    res.recordCount = 0;
                    results.add(res);
                    continue;
                }

                String safeApiName = f.getDescribe().getName();
                String safeValue = String.escapeSingleQuotes(String.isBlank(r.fieldValue) ? '' : r.fieldValue);

                if (op == 'LIKE') {
                    query += ' WHERE ' + safeApiName + ' LIKE \'%' + safeValue + '%\'';
                } else {
                    query += ' WHERE ' + safeApiName + ' ' + op + ' \'' + safeValue + '\'';
                }
            }

            query += ' LIMIT ' + lim;

            try {
                List<Lead> leadRecords = Database.query(query);
                res.recordsJson = JSON.serialize(leadRecords);
                res.recordCount = leadRecords.size();
                res.message = leadRecords.size() + ' record(s) found.';

                List<LeadRow> rows = new List<LeadRow>();
                for (Lead l : leadRecords) {
                    LeadRow row = new LeadRow();
                    row.leadId = l.Id;
                    row.firstName = l.FirstName;
                    row.lastName = l.LastName;
                    row.email = l.Email;
                    row.company = l.Company;
                    row.leadSource = l.LeadSource;
                    row.status = l.Status;
                    row.website = l.Website;
                    row.phone = l.Phone;
                    rows.add(row);
                }
                res.leads = rows;
            } catch (Exception e) {
                res.message = 'Query failed: ' + e.getMessage();
                res.recordCount = 0;
                res.leads = new List<LeadRow>();
            }
            results.add(res);
        }
        return results;
    }
}