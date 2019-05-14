<%@ Control Language="C#" AutoEventWireup="true" CodeFile="ResourceControl.ascx.cs" Inherits="SchedulerTemplatesCS.ResourceControl" %>

<%--
	This is a custom control used for editing resources that support single values.
	
	It contains a label and DropDownList.
--%>

<asp:Label runat="server" ID="ResourceLabel" Text='<%# Label %>' CssClass="rsAdvResourceLabel" />
