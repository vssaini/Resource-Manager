<%@ Page ClassName="Default" Language="C#" AutoEventWireup="true" CodeFile="Default.aspx.cs"
    Inherits="Default" %>

<%@ Reference Control="UserControl/EventToolTip.ascx" %>
<%@ Register TagPrefix="scheduler" TagName="AdvancedForm" Src="~/AdvForm/AdvancedForm.ascx" %>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
    <title>Resource Manager - Track your resources</title>
    <link rel="shortcut icon" href="Style/favicon.ico" />
    <link rel="stylesheet" type="text/css" href="Style/Style.css" />
    <link rel="stylesheet" type="text/css" href="Style/Fancybox/jquery.fancybox-1.3.4.css"
        media="screen" />
    <script type="text/javascript" src="Style/Fancybox/jquery-1.4.3.min.js"></script>
    <script type="text/javascript" src="Style/Fancybox/jquery.fancybox-1.3.4.pack.js"></script>
</head>
<body>
    <form id="form1" runat="server">
    <telerik:RadScriptManager ID="RadScriptManager1" runat="server">
        <Scripts>
            <asp:ScriptReference Path="AdvForm/AdvancedForm.js" />
        </Scripts>
    </telerik:RadScriptManager>
    <telerik:RadCodeBlock ID="RadCodeBlock1" runat="server">
        <script type="text/javascript">

            function pageLoad()
            {
                // SET DATE OF SCHEDULER HEADER
                var date = document.getElementById("hfSchedulerDate").value;
                window.$telerik.$(".rsHeader h2").text(date);

                // SET HEADER AND ROW SIZE IN SCHEDULER
                window.$telerik.$(".rsMainHeader th").css({ height: '96px' });
                window.$telerik.$(".rsContentWrapper tr").css({ height: '97px' });

                // DISABLE CONTEXT MENU FOR DISABLED CELLS
                window.$telerik.$(".Disabled").bind("contextmenu", function ()
                {
                    return false;
                });

                // BIND HYPERLINK TO SHOW IMAGE IN FANCYBOX
                $("a#hlImgRoom").fancybox({ 'type': 'image', 'overlayShow': false, 'transitionIn': 'elastic', 'transitionOut': 'elastic' });
            }

            // HIDE POPUP CALENDAR IN RADSCHEDULER
            $(document).click(function (event)
            {
                var scheduler = window.$find('<%= EventScheduler.ClientID %>'); // Return reference to Scheduler

                var target = event.target || event.srcElement;

                if (!window.$telerik.$(target).parents().is(".RadCalendar") & !window.$telerik.$(target).is(".rsDatePickerActivator"))
                {
                    if (scheduler._datePickerCalendarExpanded)
                        scheduler._onDatePickerToggle();
                }
            });

            // PREVENT INSERTING IN A DISABLE TIMESLOT
            function AppointmentInserting(sender, e)
            {
                var slotElement = window.$telerik.$(e.get_targetSlot().get_domElement());
                if (slotElement.is(".Disabled") || slotElement.parent().is(".Disabled"))
                {
                    e.set_cancel(true); // Prevent appointment inserting
                }
            }

            // PREVENT DROPPING OVER A DISABLE TIMESLOT
            function AppointmentMoveEnd(sender, e)
            {
                var slotElement = window.$telerik.$(e.get_targetSlot().get_domElement());
                if (slotElement.is(".Disabled") || slotElement.parent().is(".Disabled"))
                {
                    e.set_cancel(true);
                }
            }

            // PREVENT APPOINTMENT RESIZING OVER A DISABLE TIMESLOT
            function AppointmentResizing(sender, e)
            {
                var slotElement = window.$telerik.$(e.get_targetSlot().get_domElement());
                if (slotElement.is(".Disabled") || slotElement.parent().is(".Disabled"))
                {
                    e.set_cancel(true);
                }
            }

            // ADD APPOINTMENT ON SINGLE CLICK
            function InsertAppointment(sender, e)
            {
                var slotElement = sender.get_activeModel().getTimeSlotFromDomElement(e.get_domEvent().target);
                var domElement = e.get_targetSlot().get_domElement();
                var nodeName = $(domElement)[0].nodeName;

                switch (nodeName)
                {
                    case "DIV":
                        if (domElement.parentElement.className.match("Disabled") != "Disabled")
                            sender.showInsertFormAt(slotElement);
                        break;
                    case "TD":
                        if (domElement.className.match("Disabled") != "Disabled")
                            sender.showInsertFormAt(slotElement);
                        break;
                    default:
                }
            }

            // SHOW TOOLTIP ON ICON IMAGES
            function showToolTip(element)
            {
                var tooltipManager = window.$find("<%= IconToolTipManager.ClientID %>");

                //If the user hovers the image before the page has loaded, there is no manager created
                if (!tooltipManager) return;

                //Find the tooltip for this element if it has been created
                var tooltip = tooltipManager.getToolTipByElement(element);

                //Create a tooltip if no tooltip exists for such element  
                if (!tooltip)
                {
                    tooltip = tooltipManager.createToolTip(element);
                    tooltip.set_value(element.title);
                }

                //Let the tooltip's own show mechanism take over from here - execute the onmouseover just once
                element.onmouseover = null;

                //show the tooltip
                setTimeout(function ()
                {
                    tooltip.show();
                }, 10);
            }


            // NECESSARY FOR SHOWING ADVANCED FORM
            //<![CDATA[
            // Dictionary containing the advanced template client object
            // for a given RadScheduler instance (the control ID is used as key).
            var schedulerTemplates = {};

            function SchedulerFormCreated(scheduler, eventArgs)
            {
                // Create a client-side object only for the advanced templates
                var mode = eventArgs.get_mode();

                if (mode == window.Telerik.Web.UI.SchedulerFormMode.AdvancedInsert || mode == window.Telerik.Web.UI.SchedulerFormMode.AdvancedEdit)
                {
                    // Initialize the client-side object for the advanced form
                    var formElement = eventArgs.get_formElement();
                    var templateKey = scheduler.get_id() + "_" + mode;

                    var advancedTemplate = schedulerTemplates[templateKey];

                    if (!advancedTemplate)
                    {
                        // Initialize the template for this RadScheduler instance
                        // and cache it in the schedulerTemplates dictionary
                        var schedulerElement = scheduler.get_element();
                        var isModal = scheduler.get_advancedFormSettings().modal;
                        advancedTemplate = new window.SchedulerAdvancedTemplate(schedulerElement, formElement, isModal);
                        advancedTemplate.initialize();

                        schedulerTemplates[templateKey] = advancedTemplate;

                        // Remove the template object from the dictionary on dispose.
                        scheduler.add_disposing(function ()
                        {
                            schedulerTemplates[templateKey] = null;
                        });
                    }

                    // Are we using Web Service data binding?
                    if (!scheduler.get_webServiceSettings().get_isEmpty())
                    {
                        // Populate the form with the appointment data
                        var apt = eventArgs.get_appointment();
                        var isInsert = mode == window.Telerik.Web.UI.SchedulerFormMode.AdvancedInsert;
                        advancedTemplate.populate(apt, isInsert);
                    }
                }
            }

            //]]>
        </script>
    </telerik:RadCodeBlock>
    <telerik:RadSkinManager runat="server" ID="RadSkinManager1" Skin="Office2010Silver">
        <Skins>
            <telerik:SkinReference Path="Style/Skins" />
        </Skins>
    </telerik:RadSkinManager>
    <telerik:RadFormDecorator ID="FormDecorator1" runat="server" DecoratedControls="CheckBoxes"
        EnableEmbeddedSkins="false" />
    <telerik:RadAjaxLoadingPanel ID="RadAjaxLoadingPanel1" runat="server" EnableEmbeddedSkins="false" />
    <telerik:RadAjaxManager ID="RadAjaxManager1" runat="server">
        <AjaxSettings>
            <telerik:AjaxSetting AjaxControlID="chkLocationList">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="EventScheduler" LoadingPanelID="RadAjaxLoadingPanel1" />
                </UpdatedControls>
            </telerik:AjaxSetting>
            <telerik:AjaxSetting AjaxControlID="EventScheduler">
                <UpdatedControls>
                    <telerik:AjaxUpdatedControl ControlID="EventScheduler" LoadingPanelID="RadAjaxLoadingPanel1" />
                    <telerik:AjaxUpdatedControl ControlID="hfSchedulerDate" />
                    <telerik:AjaxUpdatedControl ControlID="EventTooltipManager" />
                    <telerik:AjaxUpdatedControl ControlID="Label1" />
                    <telerik:AjaxUpdatedControl ControlID="chkLocationList" />
                </UpdatedControls>
            </telerik:AjaxSetting>
        </AjaxSettings>
    </telerik:RadAjaxManager>
    <asp:HiddenField ID="hfSchedulerDate" runat="server" />
    <div align="center">
        <h2 class="blueText">
            <span class="orangeText">Resource</span> Manager</h2>
        <asp:Panel ID="pnlLocations" runat="server">
            <table>
                <tr>
                    <td>
                        <span>Locations:</span>
                    </td>
                    <td>
                        <asp:CheckBoxList ID="chkLocationList" runat="server" AutoPostBack="True" RepeatDirection="Horizontal"
                            DataSourceID="LocationDS" DataTextField="LocationDesc" DataValueField="LocationCode"
                            OnDataBound="chkLocationList_DataBound" OnSelectedIndexChanged="chkLocationList_SelectedIndexChanged">
                        </asp:CheckBoxList>
                    </td>
                </tr>
            </table>
        </asp:Panel>
        <br />
        <asp:Label ID="Label1" runat="server" CssClass="lblError"></asp:Label>
        <br />
        <telerik:RadScheduler runat="server" ID="EventScheduler" Skin="Office2010Silver"
            EnableEmbeddedSkins="false" ShowViewTabs="False" SelectedView="TimelineView"
            DataSourceID="EventsDS" DataKeyField="ResourceEventHeadID" DataSubjectField="ResourceEvent"
            DataStartField="EventStartDate" DataEndField="EventEndDate" DataRecurrenceField="RecurrenceRule"
            DataRecurrenceParentKeyField="RecurrenceParentID" StartEditingInAdvancedForm="True"
            StartInsertingInAdvancedForm="True" CustomAttributeNames="BookedBy,HostEmpNo,HostName,BookedByName"
            AppointmentStyleMode="Default" OverflowBehavior="Expand" RowHeaderWidth="230"
            RowHeight="48" EnableExactTimeRendering="True" ShowFooter="False" OnClientAppointmentInserting="AppointmentInserting"
            OnClientAppointmentMoveEnd="AppointmentMoveEnd" OnClientAppointmentResizing="AppointmentResizing"
            OnClientTimeSlotClick="InsertAppointment" OnClientFormCreated="SchedulerFormCreated"
            OnAppointmentDataBound="EventScheduler_AppointementDataBound" OnResourceHeaderCreated="EventScheduler_ResourceHeaderCreated"
            OnNavigationCommand="EventScheduler_NavigationCommand" OnNavigationComplete="EventScheduler_NavigationComplete"
            OnPreRender="EventScheduler_PreRender" OnTimeSlotCreated="EventScheduler_TimeSlotCreated"
            OnAppointmentCreated="EventScheduler_AppointmentCreated" OnAppointmentInsert="EventScheduler_AppointmentInsert"
            OnAppointmentUpdate="EventScheduler_AppointmentUpdate" OnAppointmentDelete="EventScheduler_AppointmentDelete"
            OnRecurrenceExceptionCreated="EventScheduler_RecurrenceExceptionCreated">
            <AdvancedForm Modal="True" EnableCustomAttributeEditing="True" />
            <TimeSlotContextMenuSettings EnableDefault="True" />
            <TimeSlotContextMenus>
                <telerik:RadSchedulerContextMenu runat="server" ID="SchedulerTimeSlotContextMenu">
                    <Items>
                        <telerik:RadMenuItem Text="New Event" ImageUrl="Style/ImgSchd/EventNew.gif" Value="CommandAddAppointment">
                        </telerik:RadMenuItem>
                        <telerik:RadMenuItem Text="New Recurring Event" ImageUrl="Style/ImgSchd/EventRecurring.gif"
                            Value="CommandAddRecurringAppointment">
                        </telerik:RadMenuItem>
                    </Items>
                </telerik:RadSchedulerContextMenu>
            </TimeSlotContextMenus>
            <TimelineView GroupBy="Room" GroupingDirection="Vertical" TimeLabelSpan="1" ColumnHeaderDateFormat="HH:mm" />
            <ResourceTypes>
                <telerik:ResourceType KeyField="ResourceID" Name="Room" TextField="ResourceName"
                    ForeignKeyField="ResourceID" DataSourceID="RoomDS" />
            </ResourceTypes>
            <ResourceHeaderTemplate>
                <div style="text-align: left; padding: 5px 0 0 5px;">
                    <asp:Label ID="lblRoom" runat="server" ForeColor="DarkBlue" Text='<%# Eval("Text") %>' />
                    <br />
                    <br />
                    <asp:HyperLink ID="hlImgRoom" runat="server" ClientIDMode="Static" NavigateUrl='<%# String.Concat(@"Handlers/ImgHandler.ashx?key=",Eval("Key")) %>'>
                        <asp:Image ID="imgRoom" runat="server" CssClass="zoomCursor" ImageUrl='<%# String.Concat(@"Handlers/ImgHandler.ashx?key=",Eval("Key")) %>' />
                    </asp:HyperLink>
                    <asp:Image ID="imgProjector" runat="server" Height="32" Width="32" Visible="False"
                        ImageUrl="Handlers/IconHandler.ashx?key=1" onmouseover='showToolTip(this);' />
                    <asp:Image ID="imgBoard" runat="server" Height="32" Width="32" Visible="False" ImageUrl="Handlers/IconHandler.ashx?key=3"
                        onmouseover='showToolTip(this);' />
                    <asp:Image ID="imgCapacity" runat="server" Height="32" Width="32" Visible="False"
                        ImageUrl="Handlers/IconHandler.ashx?key=2" onmouseover='showToolTip(this);' />
                    <asp:Label ID="lblCapacity" runat="server" Visible="False" />
                </div>
            </ResourceHeaderTemplate>
            <AdvancedInsertTemplate>
                <scheduler:AdvancedForm runat="server" ID="AdvancedFormInsert1" Mode="Insert" Subject='<%# Bind("Subject") %>'
                    Start='<%# Bind("Start") %>' End='<%# Bind("End") %>' RecurrenceRuleText='<%# Bind("RecurrenceRule") %>'
                    Booker='<%# Bind("BookedBy") %>' HostEmp='<%# Bind("HostEmpNo") %>' />
            </AdvancedInsertTemplate>
            <AdvancedEditTemplate>
                <scheduler:AdvancedForm runat="server" ID="AdvancedFormEdit1" Mode="Edit" Subject='<%# Bind("Subject") %>'
                    Start='<%# Bind("Start") %>' End='<%# Bind("End") %>' RecurrenceRuleText='<%# Bind("RecurrenceRule") %>'
                    Booker='<%# Bind("BookedBy") %>' HostEmp='<%# Bind("HostEmpNo") %>' />
            </AdvancedEditTemplate>
        </telerik:RadScheduler>
    </div>
    <%--TOOLTIP MANAGER--%>
    <telerik:RadToolTipManager runat="server" ID="EventToolTipManager" Width="180" Height="100"
        Animation="Fade" HideEvent="LeaveTargetAndToolTip" RenderInPageRoot="true" AnimationDuration="200"
        Skin="Windows7" RelativeTo="Mouse" AutoCloseDelay="7000" AutoTooltipify="False"
        EnableDataCaching="True" OnAjaxUpdate="EventToolTipManager_AjaxUpdate" EnableEmbeddedSkins="false" />
    <telerik:RadToolTipManager runat="server" ID="IconToolTipManager" Position="TopCenter"
        HideEvent="LeaveTargetAndToolTip" RenderInPageRoot="true" Skin="Sitefinity" RelativeTo="Element"
        IgnoreAltAttribute="true" EnableDataCaching="True" EnableEmbeddedSkins="false" />
    <%--SQL DATA SOURCE--%>
    <asp:SqlDataSource ID="LocationDS" runat="server" ConnectionString="<%$ ConnectionStrings:AscentDB %>" />
    <asp:SqlDataSource ID="EventsDS" runat="server" ConnectionString="<%$ ConnectionStrings:AscentDB %>">
        <DeleteParameters>
            <asp:Parameter Name="ResourceEventHeadID" Type="Int32" />
        </DeleteParameters>
        <UpdateParameters>
            <asp:Parameter Name="ResourceID" Type="Int32" />
            <asp:Parameter Name="ResourceEvent" Type="String" />
            <asp:Parameter Name="EventStartDate" Type="DateTime" />
            <asp:Parameter Name="EventEndDate" Type="DateTime" />
            <asp:Parameter Name="HostEmpNo" Type="String" />
            <asp:Parameter Name="RecurrenceRule" Type="String" />
            <asp:Parameter Name="RecurrenceParentID" Type="Int32" />
        </UpdateParameters>
        <InsertParameters>
            <asp:Parameter Name="ResourceID" Type="Int32" />
            <asp:Parameter Name="ResourceEvent" Type="String" />
            <asp:Parameter Name="EventStartDate" Type="DateTime" />
            <asp:Parameter Name="EventEndDate" Type="DateTime" />
            <asp:Parameter Name="BookedBy" Type="String" />
            <asp:Parameter Name="HostEmpNo" Type="String" />
            <asp:Parameter Name="RecurrenceRule" Type="String" />
            <asp:Parameter Name="RecurrenceParentID" Type="Int32" />
        </InsertParameters>
    </asp:SqlDataSource>
    <asp:SqlDataSource ID="RoomDS" runat="server" ConnectionString="<%$ ConnectionStrings:AscentDB %>" />
    </form>
</body>
</html>
