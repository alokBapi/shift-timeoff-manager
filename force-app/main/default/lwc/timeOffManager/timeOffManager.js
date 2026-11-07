import { LightningElement, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSubmittedRequests from '@salesforce/apex/TimeOffController.getSubmittedRequests';
import updateStatus from '@salesforce/apex/TimeOffController.updateStatus';

export default class TimeOffManager extends LightningElement {
    rows = [];
    wiredResult;

    columns = [
        { label: 'Request', fieldName: 'name' },
        { label: 'Employee', fieldName: 'employeeName' },
        { label: 'Start', fieldName: 'startDate', type: 'date-local' },
        { label: 'End', fieldName: 'endDate', type: 'date-local' },
        { label: 'Type', fieldName: 'leaveType' },
        { label: 'Reason', fieldName: 'reason' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'Approve', name: 'approve' },
                    { label: 'Reject', name: 'reject' }
                ]
            }
        }
    ];

    @wire(getSubmittedRequests)
    wiredRequests(result) {
        this.wiredResult = result;
        const { data, error } = result;
        if (data) {
            this.rows = data.map((r) => ({
                id: r.Id,
                name: r.Name,
                employeeName: r.Employee__r ? r.Employee__r.Name : '',
                startDate: r.Start_Date__c,
                endDate: r.End_Date__c,
                leaveType: r.Type__c,
                reason: r.Reason__c
            }));
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    async handleRowAction(event) {
        const newStatus = event.detail.action.name === 'approve' ? 'Approved' : 'Rejected';
        try {
            await updateStatus({ requestId: event.detail.row.id, newStatus });
            this.showToast('Success', `Request ${newStatus.toLowerCase()}`, 'success');
            await refreshApex(this.wiredResult);
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    getErrorMessage(error) {
        return error?.body?.message || 'Something went wrong';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}