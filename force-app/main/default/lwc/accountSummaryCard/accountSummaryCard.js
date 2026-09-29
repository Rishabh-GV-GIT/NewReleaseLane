import { LightningElement, api, wire } from 'lwc';
import getSummary from '@salesforce/apex/AccountSummaryController.getSummary';
import title from '@salesforce/label/c.Acct_Summary_Title';
import industry from '@salesforce/label/c.Acct_Summary_Industry';
import revenue from '@salesforce/label/c.Acct_Summary_Revenue';
import contacts from '@salesforce/label/c.Acct_Summary_Contacts';
import error from '@salesforce/label/c.Acct_Summary_Error';
import { formatRevenue, formatIndustry } from './accountFormat';

export default class AccountSummaryCard extends LightningElement {
    @api recordId;
    labels = { title, industry, revenue, contacts, error };
    summary;
    hasError = false;

    @wire(getSummary, { accountId: '$recordId' })
    wiredSummary({ data, error: wireError }) {
        if (data) {
            this.summary = data;
            this.hasError = false;
        } else if (wireError) {
            this.summary = undefined;
            this.hasError = true;
        }
    }

    get industryText() {
        return formatIndustry(this.summary && this.summary.industry);
    }

    get revenueText() {
        return formatRevenue(this.summary && this.summary.annualRevenue);
    }
}