global class LeadMcpDelete {

    global class DeleteRequest {
        @InvocableVariable(required=true) global String leadId;
    }

    global class LeadResult {
        @InvocableVariable global String leadId;
        @InvocableVariable global String message;
        @InvocableVariable global Boolean isSuccess;
    }

    @InvocableMethod(label='Delete Lead' description='Deletes a Lead record by Id.')
    global static List<LeadResult> deleteLead(List<DeleteRequest> reqs) {
        List<LeadResult> results = new List<LeadResult>();
        for (DeleteRequest r : reqs) {
            LeadResult res = new LeadResult();
            try {
                delete new Lead(Id = r.leadId);
                res.isSuccess = true;
                res.leadId = r.leadId;
                res.message = 'Lead deleted successfully.';
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Failed to delete Lead: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}