import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getEmployees from '@salesforce/apex/TimeOffController.getEmployees';
import submitRequest from '@salesforce/apex/TimeOffController.submitRequest';

export default class TimeOffRequestForm extends LightningElement {
    employeeId = '';
    startDate = '';
    endDate = '';
    leaveType = 'Annual';
    reason = '';
    employeeOptions = [];
    isSaving = false;

    typeOptions = [
        { label: 'Annual', value: 'Annual' },
        { label: 'Sick', value: 'Sick' },
        { label: 'Unpaid', value: 'Unpaid' }
    ];

    @wire(getEmployees)
    wiredEmployees({ data, error }) {
        if (data) {
            this.employeeOptions = data.map((e) => ({ label: e.Name, value: e.Id }));
        } else if (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        }
    }

    handleChange(event) {
        this[event.target.dataset.field] = event.detail.value;
    }

    async handleSubmit() {
        const fields = [...this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea')];
        const allValid = fields.reduce((valid, field) => {
            field.reportValidity();
            return valid && field.checkValidity();
        }, true);
        if (!allValid) return;

        this.isSaving = true;
        try {
            await submitRequest({
                employeeId: this.employeeId,
                startDate: this.startDate,
                endDate: this.endDate,
                leaveType: this.leaveType,
                reason: this.reason
            });
            this.showToast('Success', 'Time off request submitted', 'success');
            this.resetForm();
        } catch (error) {
            this.showToast('Error', this.getErrorMessage(error), 'error');
        } finally {
            this.isSaving = false;
        }
    }

    resetForm() {
        this.employeeId = '';
        this.startDate = '';
        this.endDate = '';
        this.leaveType = 'Annual';
        this.reason = '';
    }

    getErrorMessage(error) {
        return error?.body?.message || 'Something went wrong';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}