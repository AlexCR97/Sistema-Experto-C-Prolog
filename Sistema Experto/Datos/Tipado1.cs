using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SistemaExperto.Datos
{
    public sealed class Tipado1 : StringEnum
    {
        public static readonly Tipado1 Debil = new Tipado1("Debil");
        public static readonly Tipado1 Fuerte = new Tipado1("Fuerte");

        private Tipado1(string id) : base(id) { }
    }
}
