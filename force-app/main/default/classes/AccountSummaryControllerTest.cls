@IsTest
private class AccountSummaryControllerTest {

    @IsTest
    static void returnsSummaryWithContactCount() {
        Account acct = new Account(Name = 'UI Test Account', Industry = 'Technology', AnnualRevenue = 250000);
        insert acct;
        insert new List<Contact>{
            new Contact(LastName = 'One', AccountId = acct.Id),
            new Contact(LastName = 'Two', AccountId = acct.Id)
        };

        AccountSummaryController.Summary summary = AccountSummaryController.getSummary(acct.Id);

        System.assertEquals('UI Test Account', summary.name, 'Name');
        System.assertEquals('Technology', summary.industry, 'Industry');
        System.assertEquals(250000, summary.annualRevenue, 'Revenue');
        System.assertEquals(2, summary.contactCount, 'Contact count');
    }

    @IsTest
    static void nullIdThrows() {
        try {
            AccountSummaryController.getSummary(null);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'Null id is rejected');
        }
    }

    @IsTest
    static void unknownAccountThrows() {
        Account acct = new Account(Name = 'Temp');
        insert acct;
        Id deletedId = acct.Id;
        delete acct;
        try {
            AccountSummaryController.getSummary(deletedId);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'Missing account is rejected');
        }
    }
}