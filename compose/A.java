public class A {
	

	public static void main( String args[]) {

	A a = new A(); 
	B b = new B();

	System.out.println(" Is a equals b ? " + a.equals(b));

	}


	public boolean equals (Object obj) {

		if ( this == obj)
			return true;
		else if ( !( obj instanceof A) )
			return false ;
			else
			{return true ; }

	}


}


class B extends A {
	

}