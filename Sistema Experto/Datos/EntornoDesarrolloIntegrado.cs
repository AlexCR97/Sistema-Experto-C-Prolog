using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class EntornoDesarrolloIntegrado : StringEnum
    {
        public static readonly EntornoDesarrolloIntegrado AndroidStudio = new EntornoDesarrolloIntegrado("Android Studio");
        public static readonly EntornoDesarrolloIntegrado IntelliJ = new EntornoDesarrolloIntegrado("IntelliJ IDEA");
        public static readonly EntornoDesarrolloIntegrado Netbeans = new EntornoDesarrolloIntegrado("Netbeans");
        public static readonly EntornoDesarrolloIntegrado VisualStudio = new EntornoDesarrolloIntegrado("Visual Studio");
        public static readonly EntornoDesarrolloIntegrado VisualStudioCode = new EntornoDesarrolloIntegrado("Visual Studio Code");
        public static readonly EntornoDesarrolloIntegrado XCode = new EntornoDesarrolloIntegrado("X-Code");

        private EntornoDesarrolloIntegrado(string id) : base(id) { }
    }
}
