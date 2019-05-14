<%@ Control Language="C#" AutoEventWireup="true" CodeFile="AdvancedForm.ascx.cs"
    Inherits="AdvForm.AdvancedForm" %>
<%@ Register TagPrefix="scheduler" TagName="ResourceControl" Src="ResourceControl.ascx" %>
<div class="rsAdvancedEdit rsAdvancedModal" style="position: relative; z-index: 2501;">
    <div class="rsModalBgTopLeft">
    </div>
    <div class="rsModalBgTopRight">
    </div>
    <div class="rsModalBgBottomLeft">
    </div>
    <div class="rsModalBgBottomRight">
    </div>
    <%-- Title bar. --%>
    <div class="rsAdvTitle">
        <%-- The rsAdvInnerTitle element is used as a drag handle when the form is modal. --%>
        <h1 class="rsAdvInnerTitle">
            <%= (Mode.ToString() == "Edit") ? "Edit Event" : "New Event" %></h1>
        <asp:LinkButton runat="server" ID="AdvancedEditCloseButton" CssClass="rsAdvEditClose"
            CommandName="Cancel" CausesValidation="false" ToolTip='<%# Owner.Localization.AdvancedClose %>'>
			<%= Owner.Localization.AdvancedClose %>
        </asp:LinkButton>
    </div>
    <div class="rsAdvContentWrapper">
        <%-- Scroll container - when the form height exceeds MaximumHeight scrollbars will appear on this element--%>
        <div class="rsAdvOptionsScroll">
            <asp:Panel runat="server" ID="AdvancedEditOptionsPanel" CssClass="rsAdvOptions">
                <asp:Panel runat="server" ID="BasicControlsPanel" CssClass="rsAdvBasicControls" OnDataBinding="BasicControlsPanel_DataBinding">
                    <p class="darkBlue">
                        <scheduler:ResourceControl runat="server" ID="ResRoom" Type="Room" />
                    </p>
                    <br />
                    <telerik:RadTextBox runat="server" ID="SubjectText" Width="100%" Label='<%# "Event" + ":" %>'
                        EnableSingleInputRendering="false" EnableEmbeddedSkins="false" />
                    <asp:RequiredFieldValidator runat="server" ID="SubjectValidator" ControlToValidate="SubjectText"
                        EnableClientScript="true" Display="None" CssClass="rsValidatorMsg" />
                    <ul class="rsTimePickers">
                        <li class="rsTimePick" style="width: 244px;">
                            <label for='<%= StartDate.ClientID %>_dateInput_text'>
                                <%= Owner.Localization.AdvancedFrom %></label><%--
							    Leaving a newline here will affect the layout, so we use a comment instead.
                                --%><telerik:RadDatePicker runat="server" ID="StartDate" CssClass="rsAdvDatePicker"
                                    ShowPopupOnFocus="True" Width="83px" SharedCalendarID="SharedCalendar" Skin='<%# Owner.Skin %>'
                                    Culture='<%# Owner.Culture %>' MinDate="1900-01-01" EnableEmbeddedSkins="false">
                                    <DatePopupButton Visible="False" />
                                    <DateInput ID="DateInput2" runat="server" DateFormat='<%# Owner.AdvancedForm.DateFormat %>'
                                        EmptyMessageStyle-CssClass="riError" EmptyMessage=" " EnableSingleInputRendering="false" />
                                </telerik:RadDatePicker>
                            <%--
							
                            --%><telerik:RadTimePicker runat="server" ID="StartTime" CssClass="rsAdvTimePicker"
                                ShowPopupOnFocus="True" Width="65px" Skin='<%# Owner.Skin %>' Culture='<%# Owner.Culture %>'
                                EnableEmbeddedSkins="false">
                                <DateInput ID="DateInput3" runat="server" EmptyMessageStyle-CssClass="riError" EmptyMessage=" "
                                    EnableSingleInputRendering="false" />
                                <TimePopupButton Visible="false" />
                                <TimeView ID="TimeView1" runat="server" Columns="2" ShowHeader="false" StartTime="08:00"
                                    EndTime="18:00" Interval="00:30" />
                            </telerik:RadTimePicker>
                        </li>
                        <li class="rsTimeZonesWrapper">
                            <telerik:RadComboBox runat="server" Visible="false" ID="TimeZonesDropDown" Width="230"
                                Label="<%# Owner.Localization.AdvancedTimeZone %>" Skin='<%# Owner.Skin %>' EnableEmbeddedSkins="false">
                            </telerik:RadComboBox>
                        </li>
                        <li class="rsAllDayWrapper">
                            <asp:CheckBox runat="server" ID="AllDayEvent" CssClass="rsAdvChkWrap" Checked="false" />
                        </li>
                        <li class="rsTimePick rsEndTimePick" style="width: 244px;">
                            <label for='<%= EndDate.ClientID %>_dateInput_text'>
                                <%= Owner.Localization.AdvancedTo%></label><%--
							
                                --%><telerik:RadDatePicker runat="server" ID="EndDate" CssClass="rsAdvDatePicker"
                                    ShowPopupOnFocus="True" Width="83px" SharedCalendarID="SharedCalendar" Skin='<%# Owner.Skin %>'
                                    Culture='<%# Owner.Culture %>' MinDate="1900-01-01" EnableEmbeddedSkins="false">
                                    <DatePopupButton Visible="False" />
                                    <DateInput ID="DateInput4" runat="server" DateFormat='<%# Owner.AdvancedForm.DateFormat %>'
                                        EmptyMessageStyle-CssClass="riError" EmptyMessage=" " EnableSingleInputRendering="false" />
                                </telerik:RadDatePicker>
                            <%--
							
                            --%><telerik:RadTimePicker runat="server" ID="EndTime" CssClass="rsAdvTimePicker"
                                ShowPopupOnFocus="True" Width="65px" Skin='<%# Owner.Skin %>' Culture='<%# Owner.Culture %>'
                                EnableEmbeddedSkins="false">
                                <DateInput ID="DateInput5" runat="server" EmptyMessageStyle-CssClass="riError" EmptyMessage=" "
                                    EnableSingleInputRendering="false" />
                                <TimePopupButton Visible="false" />
                                <TimeView ID="TimeView2" runat="server" Columns="2" ShowHeader="false" StartTime="08:00"
                                    EndTime="18:00" Interval="00:30" />
                            </telerik:RadTimePicker>
                        </li>
                    </ul>
                    <div class="rsReminderWrapper">
                        <telerik:RadComboBox runat="server" ID="ReminderDropDown" Width="120px" Skin='<%# Owner.Skin %>'
                            Label="<%# Owner.Localization.Reminder %>" Visible="False" EnableEmbeddedSkins="false">
                            <Items>
                                <telerik:RadComboBoxItem Text='<%# Owner.Localization.ReminderNone %>' Value="" />
                                <telerik:RadComboBoxItem Text='<%# "0 " + Owner.Localization.ReminderMinutes %>'
                                    Value="0" />
                                <telerik:RadComboBoxItem Text='<%# "5 " + Owner.Localization.ReminderMinutes %>'
                                    Value="5" />
                                <telerik:RadComboBoxItem Text='<%# "10 " + Owner.Localization.ReminderMinutes %>'
                                    Value="10" />
                                <telerik:RadComboBoxItem Text='<%# "15 " + Owner.Localization.ReminderMinutes %>'
                                    Value="15" />
                                <telerik:RadComboBoxItem Text='<%# "30 " + Owner.Localization.ReminderMinutes %>'
                                    Value="30" />
                                <telerik:RadComboBoxItem Text='<%# "1 " + Owner.Localization.ReminderHour %>' Value="60" />
                                <telerik:RadComboBoxItem Text='<%# "2 " + Owner.Localization.ReminderHours %>' Value="120" />
                                <telerik:RadComboBoxItem Text='<%# "3 " + Owner.Localization.ReminderHours %>' Value="180" />
                                <telerik:RadComboBoxItem Text='<%# "4 " + Owner.Localization.ReminderHours %>' Value="240" />
                                <telerik:RadComboBoxItem Text='<%# "5 " + Owner.Localization.ReminderHours %>' Value="300" />
                                <telerik:RadComboBoxItem Text='<%# "6 " + Owner.Localization.ReminderHours %>' Value="360" />
                                <telerik:RadComboBoxItem Text='<%# "7 " + Owner.Localization.ReminderHours %>' Value="420" />
                                <telerik:RadComboBoxItem Text='<%# "8 " + Owner.Localization.ReminderHours %>' Value="480" />
                                <telerik:RadComboBoxItem Text='<%# "9 " + Owner.Localization.ReminderHours %>' Value="540" />
                                <telerik:RadComboBoxItem Text='<%# "10 " + Owner.Localization.ReminderHours %>' Value="600" />
                                <telerik:RadComboBoxItem Text='<%# "11 " + Owner.Localization.ReminderHours %>' Value="660" />
                                <telerik:RadComboBoxItem Text='<%# "12 " + Owner.Localization.ReminderHours %>' Value="720" />
                                <telerik:RadComboBoxItem Text='<%# "18 " + Owner.Localization.ReminderHours %>' Value="1080" />
                                <telerik:RadComboBoxItem Text='<%# "1 " + Owner.Localization.ReminderDays %>' Value="1440" />
                                <telerik:RadComboBoxItem Text='<%# "2 " + Owner.Localization.ReminderDays %>' Value="2880" />
                                <telerik:RadComboBoxItem Text='<%# "3 " + Owner.Localization.ReminderDays %>' Value="4320" />
                                <telerik:RadComboBoxItem Text='<%# "4 " + Owner.Localization.ReminderDays %>' Value="5760" />
                                <telerik:RadComboBoxItem Text='<%# "1 " + Owner.Localization.ReminderWeek %>' Value="10080" />
                                <telerik:RadComboBoxItem Text='<%# "2 " + Owner.Localization.ReminderWeeks %>' Value="20160" />
                            </Items>
                        </telerik:RadComboBox>
                    </div>
                    <asp:RequiredFieldValidator runat="server" ID="StartDateValidator" ControlToValidate="StartDate"
                        EnableClientScript="true" Display="None" CssClass="rsValidatorMsg" />
                    <asp:RequiredFieldValidator runat="server" ID="StartTimeValidator" ControlToValidate="StartTime"
                        EnableClientScript="true" Display="None" CssClass="rsValidatorMsg" />
                    <asp:RequiredFieldValidator runat="server" ID="EndDateValidator" ControlToValidate="EndDate"
                        EnableClientScript="true" Display="None" CssClass="rsValidatorMsg" />
                    <asp:RequiredFieldValidator runat="server" ID="EndTimeValidator" ControlToValidate="EndTime"
                        EnableClientScript="true" Display="None" CssClass="rsValidatorMsg" />
                    <asp:CustomValidator runat="server" ID="DurationValidator" ControlToValidate="StartDate"
                        EnableClientScript="false" Display="Dynamic" CssClass="rsValidatorMsg rsInvalid"
                        OnServerValidate="DurationValidator_OnServerValidate" />
                </asp:Panel>
                <asp:Panel runat="server" ID="AdvancedControlsPanel" CssClass="rsAdvMoreControls">
                    <asp:Panel runat="server" ID="ResourceControls">
                        <%-- RESOURCE CONTROLS --%>
                        <ul class="rsResourceControls">
                            <li>
                                <!-- Resource controls should follow the convention Res[Resource Name] for ID -->
                                <asp:Label ID="ResBooker" runat="server" Visible="False" />
                                <telerik:RadComboBox ID="ResHostEmp" runat="server" DataSourceID="EmpDS" AutoPostBack="True"
                                    AllowCustomText="true" ClientIDMode="Static" Label="Host Emp:" DataTextField="Name"
                                    DataValueField="EmpNo" Height="300px" EnableEmbeddedSkins="false" OnSelectedIndexChanged="ResHostEmp_SelectedIndexChanged"
                                    Filter="Contains" />
                                <asp:SqlDataSource ID="EmpDS" runat="server" ConnectionString="<%$ ConnectionStrings:AscentDB %>" />
                            </li>
                        </ul>
                    </asp:Panel>
                </asp:Panel>
                <span class="rsAdvResetExceptions">
                    <asp:LinkButton runat="server" ID="ResetExceptions" OnClick="ResetExceptions_OnClick" />
                </span>
                <telerik:RadSchedulerRecurrenceEditor runat="server" ID="AppointmentRecurrenceEditor"
                    EnableEmbeddedSkins="false" />
                <asp:HiddenField runat="server" ID="OriginalRecurrenceRule" />
                <telerik:RadCalendar runat="server" ID="SharedCalendar" Skin='<%# Owner.Skin %>'
                    CultureInfo='<%# Owner.Culture %>' ShowRowHeaders="false" RangeMinDate="1900-01-01"
                    EnableEmbeddedSkins="false" />
            </asp:Panel>
        </div>
        <asp:Panel runat="server" ID="ButtonsPanel" CssClass="rsAdvancedSubmitArea">
            <div class="rsAdvButtonWrapper">
                <asp:LinkButton runat="server" ID="UpdateButton" CssClass="rsAdvEditSave" CommandName="Update">
					<span><%= Owner.Localization.Save %></span>
                </asp:LinkButton>
                <asp:LinkButton runat="server" ID="CancelButton" CssClass="rsAdvEditCancel" CommandName="Cancel"
                    CausesValidation="false">
					<span><%= Owner.Localization.Cancel %></span>
                </asp:LinkButton>
            </div>
        </asp:Panel>
    </div>
</div>
