@IsTest
private class DiscountCalculatorTest {

    private static DiscountCalculator.Result calc(Decimal amount) {
        DiscountCalculator.Request req = new DiscountCalculator.Request();
        req.amount = amount;
        return DiscountCalculator.calculate(new List<DiscountCalculator.Request>{ req })[0];
    }

    // Expected values come from the deployed records, so a config-only
    // change to a tier keeps this test green.
    @IsTest
    static void eachTierBoundaryReturnsThatTiersPercent() {
        for (String tierName : new List<String>{ 'Bronze', 'Silver', 'Gold' }) {
            Discount_Tier__mdt tier = Discount_Tier__mdt.getInstance(tierName);
            DiscountCalculator.Result result = calc(tier.Min_Amount__c);
            System.assertEquals(tier.Discount_Percent__c, result.discountPercent, tierName + ' percent');
            System.assertEquals(tierName, result.tierName, tierName + ' name');
        }
    }

    @IsTest
    static void belowLowestTierOrNullGetsNoDiscount() {
        Discount_Tier__mdt bronze = Discount_Tier__mdt.getInstance('Bronze');
        System.assertEquals(0, calc(bronze.Min_Amount__c - 1).discountPercent, 'Below lowest tier');
        System.assertEquals('None', calc(bronze.Min_Amount__c - 1).tierName, 'Tier name None');
        System.assertEquals(0, calc(null).discountPercent, 'Null amount');
    }

    @IsTest
    static void bulkRequestsAreEachResolved() {
        Discount_Tier__mdt gold = Discount_Tier__mdt.getInstance('Gold');
        DiscountCalculator.Request low = new DiscountCalculator.Request();
        low.amount = 1;
        DiscountCalculator.Request high = new DiscountCalculator.Request();
        high.amount = gold.Min_Amount__c;
        List<DiscountCalculator.Result> results = DiscountCalculator.calculate(
            new List<DiscountCalculator.Request>{ low, high }
        );
        System.assertEquals(2, results.size(), 'One result per request');
        System.assertEquals(0, results[0].discountPercent, 'Low amount');
        System.assertEquals(gold.Discount_Percent__c, results[1].discountPercent, 'High amount');
    }
}