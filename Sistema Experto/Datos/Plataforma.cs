using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class Plataforma : StringEnum
    {
        public static readonly Plataforma Escritorio = new Plataforma("Escritorio");
        public static readonly Plataforma Movil = new Plataforma("Movil");
        public static readonly Plataforma Web = new Plataforma("Web");

        private Plataforma(string id) : base(id) { }
    }
}
