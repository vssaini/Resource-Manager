using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.UI.WebControls;
using Telerik.Web.UI;
using UserControl;

public partial class Default : System.Web.UI.Page
{
    private TimeSpan? _resStartTime, _resEndTime;

    #region Page Events

    protected override void OnPreLoad(EventArgs e)
    {
        Utility.SetSqlDSQueries(LocationDS, RoomDS, EventsDS);

        if (IsPostBack) return;
        Utility.RefreshContext();
        Utility.SetTooltips();
    }

    protected void Page_Load(object sender, EventArgs e)
    {
        #region Set logged in user from web.config

        // Validate user
        string userRole, userEmp;
        if (Utility.ValidateUser(out userRole, out userEmp))
            Session["User"] = new List<string> { userRole, userEmp };
        else
            Session["User"] = Utility.LoggedUserRole = Utility.LoggedUserEmp = null;

        // Save logged in user information
        if (Session["User"] == null) return;

        var data = Session["User"] as List<string>;
        if (data == null) return;

        Utility.LoggedUserRole = data[0];
        Utility.LoggedUserEmp = data[1];

        #endregion

        if (IsPostBack) return;
        Utility.SetTimeLineAttributes(EventScheduler, hfSchedulerDate);
    }

    protected void Page_LoadComplete(object sender, EventArgs e)
    {
        if (Utility.Resources != null)
            Utility.Resources.Clear();
    }

    #endregion

    #region Scheduler Events

    protected void EventScheduler_AppointementDataBound(object sender, SchedulerEventArgs e)
    {
        Utility.SetAppointmentAttributes(e);
    }

    protected void EventScheduler_ResourceHeaderCreated(object sender, ResourceHeaderCreatedEventArgs e)
    {
        Utility.SetHeaderAttributes(e);
    }

    protected void EventScheduler_TimeSlotCreated(object sender, TimeSlotCreatedEventArgs e)
    {
        var aptStartTime = e.TimeSlot.Start.TimeOfDay;
        var aptEndTime = e.TimeSlot.End.TimeOfDay;

        //Get Open and Close Time
        if (Utility.Resources != null && !Utility.Resources.Contains(e.TimeSlot.Resource.Text))
        {
            Utility.Resources.Add(e.TimeSlot.Resource.Text);
            Utility.GetHours(e.TimeSlot.Resource.Text, out _resStartTime, out _resEndTime);
        }
        else if (Utility.Resources == null)
        {
            Utility.Resources = new List<string> { e.TimeSlot.Resource.Text };
            Utility.GetHours(e.TimeSlot.Resource.Text, out _resStartTime, out _resEndTime);
        }

        if (Utility.IsBlockedTimeSlot(aptStartTime, aptEndTime, _resStartTime, _resEndTime))
        {
            e.TimeSlot.CssClass = "Disabled";
        }
    }

    protected void EventScheduler_NavigationCommand(object sender, SchedulerNavigationCommandEventArgs e)
    {
        switch (e.Command)
        {
            case SchedulerNavigationCommand.NavigateToPreviousPeriod:
                //EventScheduler.SelectedDate = Utility.GetDate(Utility.Commands.Prev, EventScheduler.SelectedDate);
                break;

            case SchedulerNavigationCommand.NavigateToNextPeriod:
                EventScheduler.SelectedDate = Utility.GetDate(Utility.Commands.Next, EventScheduler.SelectedDate);
                break;
        }
    }

    protected void EventScheduler_NavigationComplete(object sender, SchedulerNavigationCompleteEventArgs e)
    {
        if (EventScheduler.SelectedView != SchedulerViewType.TimelineView) return;
        Utility.SetTimeLineAttributes(EventScheduler, hfSchedulerDate);
    }

    protected void EventScheduler_PreRender(object sender, EventArgs e)
    {
        // Set Scheduler width as per timeslots
        var slotsWidth = Convert.ToInt32(Utility.NumberOfSlots * 51);
        const int rowHeaderWidth = 230;
        EventScheduler.Width = Unit.Pixel(slotsWidth + rowHeaderWidth);

        // Hide location panel if no resources
        var resources = from c in Utility.EssResources select c;
        pnlLocations.Visible = resources.Any();
    }

    #endregion

    #region Appointement Insert, Update & Delete

    protected void EventScheduler_AppointmentInsert(object sender, AppointmentInsertEventArgs e)
    {
        if (Session["User"] != null)
        {
            var aptStartTime = e.Appointment.Start.TimeOfDay;
            var aptEndTime = e.Appointment.End.TimeOfDay;
            var resource = e.Appointment.Resources.GetResourceByType("Room");

            // Check if blocked timeslot
            Utility.GetHours(resource.Text, out _resStartTime, out _resEndTime);
            if (Utility.IsBlockedTimeSlot(aptStartTime, aptEndTime, _resStartTime, _resEndTime))
            {
                e.Cancel = true;
                ShowErrorMessage("Creating events in blocked timeslot is not allowed.");
            }

            // Check if there is alreay an appointment
            if (Utility.ExceedsLimit(e.Appointment, EventScheduler))
            {
                e.Cancel = true;
                ShowErrorMessage("Creating events in occupied timeslot is not allowed.");
            }
        }
        else
        {
            e.Cancel = true;
            ShowErrorMessage("Only logged in user can create events.");
        }
    }

    protected void EventScheduler_AppointmentUpdate(object sender, AppointmentUpdateEventArgs e)
    {
        if (Session["User"] != null)
        {
            var aptStartTime = e.Appointment.Start.TimeOfDay;
            var aptEndTime = e.Appointment.End.TimeOfDay;
            var resource = e.Appointment.Resources.GetResourceByType("Room");

            // Do not allow for blocked timeslot to anyone
            Utility.GetHours(resource.Text, out _resStartTime, out _resEndTime);
            if (Utility.IsBlockedTimeSlot(aptStartTime, aptEndTime, _resStartTime, _resEndTime))
            {
                e.Cancel = true;
                ShowErrorMessage("Updating events in blocked timeslot is not allowed.");
            }

            // If it is not user's created event
            if (Utility.LoggedUserRole == "User" && !e.Appointment.Attributes["BookedBy"].Equals(Utility.LoggedUserEmp))
            {
                e.Cancel = true;
                ShowErrorMessage("You cannot modify other user's created events.");
            }

            // If appointment overlaps
            if (Utility.AppointmentsOverlap(e.ModifiedAppointment, EventScheduler))
            {
                e.Cancel = true;
                ShowErrorMessage("Updating events in occupied timeslot is not allowed.");
            }
        }
        else
        {
            e.Cancel = true;
            ShowErrorMessage("Only logged in user can modify events.");
        }
    }

    protected void EventScheduler_AppointmentDelete(object sender, AppointmentDeleteEventArgs e)
    {
        if (Session["User"] != null)
        {
            if (Utility.LoggedUserRole == "User" && !e.Appointment.Attributes["BookedBy"].Equals(Utility.LoggedUserEmp))
            {
                e.Cancel = true;
                ShowErrorMessage("You cannot delete other user's created events.");
            }
        }
        else
        {
            e.Cancel = true;
            ShowErrorMessage("Only logged in user can delete events.");
        }

    }

    protected void EventScheduler_RecurrenceExceptionCreated(object sender, RecurrenceExceptionCreatedEventArgs e)
    {
        if (!Utility.AppointmentsOverlap(e.ExceptionAppointment, EventScheduler)) return;
        e.Cancel = true;
        ShowErrorMessage("Exception occured. You are trying disabled actions.");
    }

    #endregion

    #region Show Tooltip in EventScheduler

    protected void EventScheduler_AppointmentCreated(object sender, AppointmentCreatedEventArgs e)
    {
        if (!e.Appointment.Visible || IsAppointmentRegisteredForTooltip(e.Appointment)) return;

        var id = e.Appointment.ID.ToString();

        foreach (var domElementID in e.Appointment.DomElements)
        {
            EventToolTipManager.TargetControls.Add(domElementID, id, true);
        }
    }

    private bool IsAppointmentRegisteredForTooltip(Appointment apt)
    {
        return EventToolTipManager.TargetControls.Cast<ToolTipTargetControl>().Any(targetControl => apt.DomElements.Contains(targetControl.TargetControlID));
    }

    protected void EventToolTipManager_AjaxUpdate(object sender, ToolTipUpdateEventArgs e)
    {
        var appointment = EventScheduler.Appointments.FirstOrDefault(apt => apt.ID.ToString().Equals(e.Value));
        if (appointment == null) return;

        var toolTip = (EventToolTip)LoadControl("UserControl/EventToolTip.ascx");
        toolTip.TargetAppointment = appointment;
        e.UpdatePanel.ContentTemplateContainer.Controls.Add(toolTip);
    }

    #endregion

    #region Location and Filter

    protected void chkLocationList_DataBound(object sender, EventArgs e)
    {
        for (var i = 0; i < chkLocationList.Items.Count; i++)
        {
            chkLocationList.Items[i].Selected = true;
            chkLocationList.Items[i].Text = System.Threading.Thread.CurrentThread.CurrentCulture.TextInfo.ToTitleCase(chkLocationList.Items[i].Text.ToLower());
        }
    }

    protected void chkLocationList_SelectedIndexChanged(object sender, EventArgs e)
    {
        RoomDS.SelectCommand = Utility.FilterQuery(chkLocationList);
        RoomDS.DataBind();
        EventScheduler.Rebind();
    }

    #endregion

    /// <summary>
    /// Show message to users for insert or update events in Scheduler from Advanced Form.
    /// </summary>
    /// <param name="message">Message to show to user.</param>
    private void ShowErrorMessage(string message)
    {
        Label1.Text = message;
        System.Web.UI.ScriptManager.RegisterClientScriptBlock(this, GetType(), "LabelUpdated", "$telerik.$('.lblError').show().animate({ opacity: 0.9 }, 3000).fadeOut('slow');", true);
    }
}
