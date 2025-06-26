public class MyClass {

    int ex = 0;

    public void printDetails(int i) {
        int ex=-1;
        
        System.out.println("ex (object field): " + ex);

    }

    public static void main(String[] args) {
        MyClass obj = new MyClass();
        obj.printDetails(5);
    }
}
