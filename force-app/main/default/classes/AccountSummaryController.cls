/**
 * Backs the accountSummaryCard LWC. Standard object and standard fields only.
 */
public with sharing class AccountSummaryController {

    public class Summary {
        @AuraEnabled public String name;
        @AuraEnabled public String industry;
        @AuraEnabled public Decimal annualRevenue;
        @AuraEnabled public Integer contactCount;
    }

    @AuraEnabled(cacheable=true)
    public static Summary getSummary(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('An account id is required.');
        }
        List<Account> rows = [
            SELECT Name, Industry, AnnualRevenue
            FROM Account
            WHERE Id = :accountId
            WITH USER_MODE
            LIMIT 1
        ];
        if (rows.isEmpty()) {
            throw new AuraHandledException('Account not found.');
        }
        Summary result = new Summary();
        result.name = rows[0].Name;
        result.industry = rows[0].Industry;
        result.annualRevenue = rows[0].AnnualRevenue;
        result.contactCount = [SELECT COUNT() FROM Contact WHERE AccountId = :accountId WITH USER_MODE];
        return result;
    }
}