# lib<project>


Setup:

```sed
find . -type f -exec sed -i "s/<project>/<project-name>/g" {} \;
```

```sed
sed -i "s/<year>/$(date +%Y)/" LICENSE
```

```bash
touch include/lib<project>.h
```

```bash
mv _.github .github
```
