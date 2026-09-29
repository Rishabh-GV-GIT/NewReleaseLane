export function formatRevenue(value) {
    if (value === null || value === undefined || isNaN(value)) {
        return 'n/a';
    }
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(value);
}

export function formatIndustry(value) {
    return value ? value : 'Not set';
}