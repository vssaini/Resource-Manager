using System;
using System.ComponentModel;
using System.IO;
using System.Web.UI;
using Telerik.Web.UI;

namespace SchedulerTemplatesCS
{
    public partial class ResourceControl : UserControl
    {
        private object _key;

        protected Appointment Appointment
        {
            get
            {
                var container = (SchedulerFormContainer)BindingContainer;
                return container.Appointment;
            }
        }

        protected RadScheduler Owner
        {
            get
            {
                return Appointment.Owner;
            }
        }

        [Bindable(BindableSupport.Yes, BindingDirection.TwoWay)]
        public string Label
        {
            get
            {
                if (!String.IsNullOrEmpty(ResourceLabel.Text))
                {
                    return ResourceLabel.Text;
                }

                return String.Empty;
            }
            set
            {
                ResourceLabel.Text = value;
            }
        }

        [Bindable(BindableSupport.Yes, BindingDirection.TwoWay)]
        public object Value
        {
            get
            {
                return _key ?? string.Empty;
            }
            set
            {
                _key = value;
            }
        }

        [Bindable(BindableSupport.Yes, BindingDirection.OneWay)]
        public string Type { get; set; }

        protected void Page_Load(object sender, EventArgs e)
        {
            MarkSelectedResource();
        }

        /// <summary>
        /// Marks (selects) the resource currently associated with the appointment.
        /// </summary>
        private void MarkSelectedResource()
        {
            var res = Appointment.Resources.GetResourceByType(Type);
            if (res == null) return;

            Value = SerializeResourceKey(res.Key);
            ResourceLabel.Text = res.Text;
        }

        /// <summary>
        /// Serializes a resource key using LosFormatter.
        /// </summary>
        /// <remarks>
        ///	The resource keys need to be serialized as they can be arbitrary objects.
        /// </remarks>
        /// <param name="key">The key to serialize.</param>
        /// <returns>The serialized key.</returns>
        private static string SerializeResourceKey(object key)
        {
            var output = new LosFormatter();
            var writer = new StringWriter();
            output.Serialize(writer, key);
            return writer.ToString();
        }

        /// <summary>
        /// Deserializes a resource key using LosFormatter.
        /// </summary>
        /// <remarks>
        ///	The resource keys need to be serialized as they can be arbitrary objects.
        /// </remarks>
        /// <param name="key">The key to deserialize.</param>
        /// <returns>The deserialized key.</returns>
        private static object DeserializeResourceKey(string key)
        {
            var input = new LosFormatter();
            return input.Deserialize(key);
        }
    }
}