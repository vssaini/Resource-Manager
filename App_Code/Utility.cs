/****************************** Module Utility ******************************************************\
* Module Name:  Utility.cs
* Project:      Resource Manager
* Date:         29th Nov, 2013
* Copyright (c) Vikram Singh Saini
* 
* Provide functions for setting Scheduler's appointment attributes, timelineview, header attributes.
* Filter query, Get resource hours from database, validate user and check blocked timeslot.
* 
* THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, 
* EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED 
* WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.
\******************************************************************************************************/

using System;
using System.Collections;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Web.UI.WebControls;
using ESSLib.Data;
using ESSLib.Data.DataObjects;
using Telerik.Web.UI;
using Resource = ESSLib.Data.DataObjects.Resource;
using ResourceCollection = ESSLib.Data.DataObjects.ResourceCollection;

/// <summary>
/// Multifunctionality class that provide functions for setting Scheduler's appointment attributes, timelineview, header attributes. In addition it 
/// provides function for filter query, get resource hours from database, validate user and check blocked timeslot.
/// </summary>
public static class Utility
{
    public enum Commands { Prev, Next };

    #region Properties

    /// <summary>
    /// Resources from table C01RM0100.
    /// </summary>
    public static ResourceCollection EssResources { get; set; }

    /// <summary>
    /// Resources from table C01RM0110.
    /// </summary>
    public static ResourceDetailCollection EssResourceDetail { get; set; }

    /// <summary>
    /// Resources from table C01RM0190
    /// </summary>
    public static ResourceAttributeCollection EssResourceAttribute { get; set; }

    /// <summary>
    /// Server as container for resources.
    /// </summary>
    public static List<string> Resources { get; set; }

    /// <summary>
    /// Minimum starting time for Scheduler in database.
    /// </summary>
    public static TimeSpan OpenTime { get; set; }

    /// <summary>
    /// Maximum ending time for Scheduler in database.
    /// </summary>
    public static TimeSpan CloseTime { get; set; }

    /// <summary>
    /// Logged in user's role.
    /// </summary>
    public static string LoggedUserRole { get; set; }

    /// <summary>
    /// Logged in user's emp number.
    /// </summary>
    public static string LoggedUserEmp { get; set; }

    /// <summary>
    /// Number of slots.
    /// </summary>
    public static int NumberOfSlots { get; set; }

    /// <summary>
    /// Set or get tooltip data for icons.
    /// </summary>
    public static List<Tuple<int, string>> Tooltips { get; set; }

    #endregion

    #region E V E N T SCHEDULER

    /// <summary>
    /// Set icons and text in ResourceHeaderTemplate with values from database.
    /// </summary>
    /// <param name="args">Argument of type Telerik.Web.UI.ResourceHeaderCreatedEventArgs</param>
    public static void SetHeaderAttributes(ResourceHeaderCreatedEventArgs args)
    {
        var key = Convert.ToInt32(Convert.ToString(args.Container.Resource.Key));

        // Information about resources icons and images
        // RaId - 1=Projector, 2=Capacity, 3=Whiteboard
        // RaValueType - B=Boolean, N=Number
        // RaValue - Yes - Show board & projector, Number - Show capacity

        #region Set icon(s) tooltip and visibility

        var records = from c in EssResourceDetail
                      where c.ResourceID.Equals(key)
                      select new
                          {
                              RaId = c.ResourceAttributeID,
                              RaValueType = c.ResourceAttributeValueType,
                              RaValue = c.ResourceAttributeValue
                          };

        foreach (var record in records)
        {
            switch (record.RaValueType)
            {
                case "B":
                    if (record.RaValue.Equals("Yes"))
                    {
                        switch (record.RaId)
                        {
                            case 1:
                                var projectorImg = args.Container.FindControl("imgProjector") as Image;
                                if (projectorImg != null)
                                {
                                    projectorImg.Visible = true;
                                    projectorImg.ToolTip = GetTooltip((int)record.RaId);
                                }
                                break;

                            case 3:
                                var boardImg = args.Container.FindControl("imgBoard") as Image;
                                if (boardImg != null)
                                {
                                    boardImg.Visible = true;
                                    boardImg.ToolTip = GetTooltip((int)record.RaId);
                                }
                                break;
                        }
                    }
                    else
                    {
                        args.Container.FindControl("imgProjector").Visible = args.Container.FindControl("imgBoard").Visible = false;
                    }
                    break;

                case "N":
                    if ((Int32.Parse(record.RaValue)) > 0 && record.RaId.Equals(2))
                    {
                        var capacityImg = args.Container.FindControl("imgCapacity") as Image;
                        var capacityLbl = args.Container.FindControl("lblCapacity") as Label;

                        if (capacityImg != null && capacityLbl != null)
                        {
                            capacityImg.ToolTip = GetTooltip((int)record.RaId);
                            capacityImg.Visible = capacityLbl.Visible = true;
                            capacityLbl.Text = "(" + record.RaValue + ")";
                        }
                    }
                    else
                    {
                        args.Container.FindControl("imgCapacity").Visible = args.Container.FindControl("lblCapacity").Visible = false;
                    }
                    break;
            }
        }

        #endregion
    }

    /// <summary>
    /// Set color for appointments using pre-defined css classes in Telerik library. 
    /// <para>For more details check : http://www.telerik.com/help/aspnet-ajax/scheduler-appearance-setting-appointment-style.html</para>
    /// </summary>
    /// <param name="e">Argument of type Telerik.Web.UI.SchedulerEventArgs</param>
    public static void SetAppointmentAttributes(SchedulerEventArgs e)
    {
        e.Appointment.ToolTip = string.Empty; // To avoid it's default tooltip
        e.Appointment.CssClass = e.Appointment.Attributes["BookedBy"].Equals(LoggedUserEmp) ? "rsCategoryGreen" : "rsCategoryYellow";
    }

    /// <summary>
    /// Set header of scheduler. Also set start time and end time of TimeLineView.
    /// </summary>
    /// <param name="scheduler">Scheduler whose TimeLineView need to be set.</param>
    /// <param name="hiddenHeader">HiddenField which will be used to customize header of Scheduler.</param>
    public static void SetTimeLineAttributes(RadScheduler scheduler, HiddenField hiddenHeader)
    {
        scheduler.SelectedDate = scheduler.SelectedDate.Date;
        hiddenHeader.Value = String.Format("{0:dddd, MMMM d, yyyy}", scheduler.SelectedDate);

        scheduler.TimelineView.StartTime = OpenTime;
        scheduler.TimelineView.SlotDuration = TimeSpan.FromHours(1);
        scheduler.TimelineView.NumberOfSlots = NumberOfSlots = (CloseTime.Subtract(OpenTime)).Hours;
    }

    #endregion

    #region H E L P E R S

    /// <summary>
    /// Refresh database context, open time and close time of resources.
    /// </summary>
    public static void RefreshContext()
    {
        EssResources = Resource.LoadList();
        EssResourceDetail = ResourceDetail.LoadList();
        OpenTime = Convert.ToDateTime((from c in EssResources select c.BookingOpenFrom).Min()).TimeOfDay;
        CloseTime = Convert.ToDateTime((from c in EssResources select c.BookingOpenTo).Max()).TimeOfDay;
    }

    /// <summary>
    /// Fetch records once from C01RM0190 for tooltip purpose.
    /// </summary>
    public static void SetTooltips()
    {
        Tooltips = new List<Tuple<int, string>>();

        EssResourceAttribute = ResourceAttribute.LoadList();
        var records = from c in EssResourceAttribute
                      select new
                      {
                          ResId = c.ResourceAttributeID,
                          ResName = c.ResourceAttributeName
                      };

        foreach (var record in records)
        {
            Tooltips.Add(new Tuple<int, string>((int)record.ResId, record.ResName));
        }
    }

    /// <summary>
    /// Get text for tooltip for icons in resource header template.
    /// </summary>
    /// <param name="id"></param>
    /// <returns></returns>
    public static string GetTooltip(int id)
    {
        var tuple = Tooltips[id - 1];
        return tuple.Item1.Equals(id) ? tuple.Item2 : "NA";
    }

    /// <summary>
    /// Generate query based on location filters selected by user.
    /// </summary>
    /// <param name="checkBoxList">CheckBoxList control from which selected items will be retrieved.</param>
    /// <returns>Return complete builded query along with filters.</returns>
    public static string FilterQuery(ListControl checkBoxList)
    {
        var query = "SELECT [ResourceID], [ResourceName] FROM " + Tables.tblResource + " WHERE [LocationCode] IN ('";

        string sqlFinal;
        var queryBuilder = new StringBuilder(query);

        var chkList = new ArrayList();
        foreach (var item in checkBoxList.Items.Cast<ListItem>().Where(item => item.Selected))
        {
            chkList.Add(item.Value);
        }

        // Build final query
        if (chkList.Capacity > 0)
        {
            queryBuilder.Append(chkList[0]).Append("',");

            for (var i = 1; i < chkList.Count; i++)
            {
                queryBuilder.Append("'").Append(chkList[i]).Append("',");
            }

            var sql = queryBuilder.ToString().TrimEnd(',');
            sqlFinal = sql + ")";
        }
        else
        {
            // For sending blank data when no location selected
            sqlFinal = query + "VSS')";
        }

        return sqlFinal;
    }

    /// <summary>
    /// Retrieve booking open time to close time from table for respective resources.
    /// </summary>
    /// <param name="resName">Name of resource for which time need to be retrieved.</param>
    /// <param name="openTime">TimeSpan parameter in which open time will be set.</param>
    /// <param name="closeTime">TimeSpan parameter in which close time will be set.</param>
    public static void GetHours(string resName, out TimeSpan? openTime, out TimeSpan? closeTime)
    {
        EssResources = Resource.LoadList();
        var bookingHours = from c in EssResources
                           where c.ResourceName.Equals(resName)
                           select new
                           {
                               OpenTime = c.BookingOpenFrom,
                               CloseTime = c.BookingOpenTo
                           };

        var hourData = bookingHours.FirstOrDefault();

        if (hourData != null)
        {
            openTime = (Convert.ToDateTime(hourData.OpenTime)).TimeOfDay;
            closeTime = (Convert.ToDateTime(hourData.CloseTime)).TimeOfDay;
        }
        else
        {
            openTime = closeTime = null;
        }
    }

    /// <summary>
    /// Validate authenticity of user using credentials provided.
    /// </summary>
    /// <param name="role">Role of user as 'Admin' or 'User'.</param>
    /// <param name="userEmp">Emp number of user. </param>
    /// <returns>Return true if record matches.</returns>
    public static bool ValidateUser(out string role, out string userEmp)
    {
        userEmp = ConfigurationManager.AppSettings["UserEmp"];
        var userRole = ConfigurationManager.AppSettings["UserLevel"];
        role = Convert.ToInt32(userRole).Equals(1) ? "Admin" : "User";
        return true;
    }

    /// <summary>
    /// Check if specified event time range falls out of allowed resources time range.
    /// </summary>
    /// <param name="aptStartTime">Time at which event starts.</param>
    /// <param name="aptEndTime">Time at which event ends.</param>
    /// <param name="resStartTime">Allowed start time for resource.</param>
    /// <param name="resEndTime">Allowed end time for resource.</param>
    /// <returns>Return true if timeslot falls in blocked category.</returns>
    public static bool IsBlockedTimeSlot(TimeSpan aptStartTime, TimeSpan aptEndTime, TimeSpan? resStartTime, TimeSpan? resEndTime)
    {
        return (resStartTime > aptStartTime) || (resEndTime < aptEndTime);
    }

    /// <summary>
    /// Get date on basis of commands passed.
    /// </summary>
    /// <param name="cmd">Type of command enum based on dates to be retrieved.</param>
    /// <param name="date">Selected date of RadScheduler</param>
    /// <returns></returns>
    public static DateTime GetDate(Commands cmd, DateTime date)
    {
        var dateSet = date;

        var year = date.Year;
        var month = date.Month;
        var nDay = date.Day + 1;
        var pDay = date.Day - 1;

        var hour = OpenTime.Hours;
        var minute = OpenTime.Minutes;
        var second = OpenTime.Seconds;

        switch (cmd)
        {
            case Commands.Prev:

                if (month.Equals(1) && date.Day.Equals(1)) // January Month
                {
                    // Set to 31st day of Dec of prev year
                    dateSet = new DateTime(year - 1, 12, 31, hour, minute, second);
                }
                else
                {
                    if (date.Day.Equals(1))
                    {
                        var prevMonth = --month;
                        var lastDay = DateTime.DaysInMonth(date.Year, prevMonth);

                        dateSet = new DateTime(year, prevMonth, lastDay, hour, minute, second);
                    }
                    else
                    {
                        dateSet = new DateTime(year, month, pDay, hour, minute, second);
                    }
                }
                break;

            case Commands.Next:
                var totalDays = DateTime.DaysInMonth(date.Year, date.Month);
                if (month.Equals(12)) //December month
                {
                    // Set to 1st day of Jan month of next year
                    dateSet = date.Day.Equals(totalDays) ? new DateTime(year + 1, 1, 1, hour, minute, second) : new DateTime(year, month, nDay, hour, minute, second);
                }
                else
                {
                    dateSet = date.Day.Equals(totalDays) ? new DateTime(year, ++month, 1, hour, minute, second) : new DateTime(year, month, nDay, hour, minute, second);
                }
                break;
        }

        return dateSet;
    }

    /// <summary>
    /// Check if event exceeds limit of more than one event.
    /// </summary>
    /// <param name="apt">Appointment object which needs to be checked.</param>
    /// <param name="scheduler">RadScheduler in which appointment would be created.</param>
    /// <returns>Return true if event exceeds limit.</returns>
    public static bool ExceedsLimit(Appointment apt, RadScheduler scheduler)
    {
        const int aptLimit = 1;
        var aptRoom = apt.Resources.GetResourceByType("Room");

        var aptCount = (from existingApt in scheduler.Appointments.GetAppointmentsInRange(apt.Start, apt.End) let exstAptRoom = existingApt.Resources.GetResourceByType("Room") where existingApt.Visible && exstAptRoom.Equals(aptRoom) select existingApt).Count();

        return (aptCount > aptLimit - 1);
    }

    /// <summary>
    /// Check if event overlaps another event.
    /// </summary>
    /// <param name="apt">Appointment object which needs to be checked.</param>
    /// <param name="scheduler">RadScheduler in which appointment would be created.</param>
    /// <returns>Return true if event overlap.</returns>
    public static bool AppointmentsOverlap(Appointment apt, RadScheduler scheduler)
    {
        if (ExceedsLimit(apt, scheduler))
        {
            var aptRoom = apt.Resources.GetResourceByType("Room");

            var resAppts = (from existApt in scheduler.Appointments.GetAppointmentsInRange(apt.Start, apt.End) let exstAptRoom = existApt.Resources.GetResourceByType("Room") where aptRoom.Equals(exstAptRoom) select existApt).ToList();

            var aptId = Convert.ToInt32(Convert.ToString(apt.ID));
            return resAppts.Select(a => Convert.ToInt32(Convert.ToString(a.ID))).Any(aId => aId != aptId);
        }
        return false;
    }

    /// <summary>
    /// Set different queries for SqlDataSource(s) used in website.
    /// </summary>
    /// <param name="locationDS">SqlDataSource named LocationDS.</param>
    /// <param name="roomDS">SqlDataSource named RoomDS.</param>
    /// <param name="eventsDS">SqlDataSource named EventsDS.</param>
    public static void SetSqlDSQueries(SqlDataSource locationDS, SqlDataSource roomDS, SqlDataSource eventsDS)
    {
        // Get dynamic table names including company code automatically
        var tblLocation = Tables.tblLocation; // C01PR2800
        var tblResource = Tables.tblResource; // C01RM0100
        var tblResourceEvent = Tables.tblResourceEvent; // C01RM0200
        var tblEmployees = Tables.tblEmployees; //C01PR0100

        locationDS.SelectCommand = "SELECT [LocationCode],[LocationDesc] FROM " + tblLocation + " LM WHERE EXISTS (SELECT LocationCode FROM " + tblResource + " RM WHERE LM.LocationCode=RM.LocationCode)";

        roomDS.SelectCommand = "SELECT [ResourceID], [ResourceName] FROM " + tblResource;

        eventsDS.SelectCommand = "SELECT ResourceEvent.*,EMP.Name AS HostName,EMPL.Name as BookedByName  FROM " + tblResourceEvent + " ResourceEvent  INNER JOIN " + tblEmployees + " EMP ON ResourceEvent.HostEmpNo=EMP.EmpNo  INNER JOIN " + tblEmployees + " EMPL ON ResourceEvent.BookedBy=EMPL.EmpNo ";

        eventsDS.InsertCommand =
            "INSERT INTO " + tblResourceEvent + " ([ResourceEvent], [EventStartDate], [EventEndDate], [ResourceID], [BookedBy], [HostEmpNo], [RecurrenceRule], [RecurrenceParentID]) VALUES (@ResourceEvent, @EventStartDate, @EventEndDate , @ResourceID, @BookedBy,@HostEmpNo, @RecurrenceRule, @RecurrenceParentID)";
        eventsDS.UpdateCommand = "UPDATE " + tblResourceEvent + " SET [ResourceEvent] = @ResourceEvent, [EventStartDate] = @EventStartDate, [EventEndDate] = @EventEndDate, [HostEmpNo]=@HostEmpNo,[RecurrenceRule] = @RecurrenceRule, [RecurrenceParentID] = @RecurrenceParentID WHERE (ResourceEventHeadID = @ResourceEventHeadID)";
        eventsDS.DeleteCommand = "DELETE FROM " + tblResourceEvent + " WHERE [ResourceEventHeadID] = @ResourceEventHeadID";
    }

    #endregion
}