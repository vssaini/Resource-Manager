using System;
using System.Text;
using Telerik.Web.UI;

namespace UserControl
{
    public partial class EventToolTip : System.Web.UI.UserControl
    {
        private Appointment _apt;

        public Appointment TargetAppointment
        {
            get
            {
                return _apt;
            }

            set
            {
                _apt = value;
            }
        }

        protected override void OnPreRender(EventArgs e)
        {
            base.OnPreRender(e);

            // Set EmpName and HostName
            var empName = _apt.Attributes["BookedByName"];
            var hostName = _apt.Attributes["HostName"];

            if (empName != null && hostName != null)
            {
                var builder = new StringBuilder("<b>Booked by :-</b> <br/><br/> Employee - <i>");
                builder.Append(empName).Append("</i> <br/>Host - <i>").Append(hostName).Append("</i>");

                BookingDetail.Text = builder.ToString();
            }
            else
            {
                BookingDetail.Text = "<i>Booking information not available</i>";
            }
        }
    }
}
