using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public class Framework
    {
        public string Nombre { get; set; }
        public string Descripcion { get; set; }
        public List<string> Ventajas { get; set; }
        public List<string> Desventajas { get; set; }
        public Plataforma Plataforma { get; set; }
        public SistemaOperativo SistemaOperativo { get; set; }
        public LenguajeProgramacion Lenguaje { get; set; }
        public LadoDesarrollo LadoDesarrollo { get; set; }
        public EntornoDesarrolloIntegrado Ide { get; set; }
        public RequisitosHardware Hardware { get; set; }
    }
}
