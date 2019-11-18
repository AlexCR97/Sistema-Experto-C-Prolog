using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class LadoDesarrollo : StringEnum
    {
        public static readonly LadoDesarrollo Backend = new LadoDesarrollo("Backend");
        public static readonly LadoDesarrollo Frontend = new LadoDesarrollo("Frontend");

        private LadoDesarrollo(string id) : base(id) { }
    }
}
