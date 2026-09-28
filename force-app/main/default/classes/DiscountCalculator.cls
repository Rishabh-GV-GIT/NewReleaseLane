/**
 * Invocable action called by Subflow_Apply_Discount.
 * Reads Discount_Tier__mdt and returns the discount of the highest active
 * tier whose Min_Amount__c is <= the amount. No SOQL/DML, so it is bulk-safe.
 */
public with sharing class DiscountCalculator {

    public class Request {
        @InvocableVariable(label='Amount' required=true)
        public Decimal amount;
    }

    public class Result {
        @InvocableVariable(label='Discount Percent')
        public Decimal discountPercent;
        @InvocableVariable(label='Tier Name')
        public String tierName;
    }

    @InvocableMethod(label='Calculate Discount' category='Discounts')
    public static List<Result> calculate(List<Request> requests) {
        List<Discount_Tier__mdt> tiers = new List<Discount_Tier__mdt>();
        for (Discount_Tier__mdt tier : Discount_Tier__mdt.getAll().values()) {
            if (tier.Is_Active__c == true && tier.Min_Amount__c != null) {
                tiers.add(tier);
            }
        }
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(resolve(req.amount, tiers));
        }
        return results;
    }

    private static Result resolve(Decimal amount, List<Discount_Tier__mdt> tiers) {
        Result result = new Result();
        result.discountPercent = 0;
        result.tierName = 'None';
        if (amount == null) {
            return result;
        }
        Decimal bestMinimum = -1;
        for (Discount_Tier__mdt tier : tiers) {
            if (tier.Min_Amount__c <= amount && tier.Min_Amount__c > bestMinimum) {
                bestMinimum = tier.Min_Amount__c;
                result.discountPercent = tier.Discount_Percent__c == null ? 0 : tier.Discount_Percent__c;
                result.tierName = tier.DeveloperName;
            }
        }
        return result;
    }
}