from backend.app import create_app
from backend.extensions import db
from backend.models import Project


def main():
    app = create_app()
    with app.app_context():
        items = []
        for i in range(1, 18):
            items.append(Project(
                title=f"Proyecto {i}",
                description=f"Descripción breve del proyecto {i} con objetivos e impacto.",
                technologies="Flutter, Flask, PostgreSQL" if i % 2 == 0 else "Dart, Python, SQLite",
                category="mobile" if i % 3 == 0 else "web",
                featured=(i % 5 == 0),
            ))
        db.session.add_all(items)
        db.session.commit()
        print("Seeded 17 projects.")


if __name__ == "__main__":
    main()


